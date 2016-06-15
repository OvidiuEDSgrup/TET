--***  
/* handler comanda deschisa pe tert */
CREATE procedure [dbo].[wmComandaTertDeschisaHandler] @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmComandaTertDeschisaHandlerSP' and type='P')
begin
	exec wmComandaTertDeschisaHandlerSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @idPunctLivrare varchar(100),
		@comanda varchar(20), @explicatii varchar(100), @linietotal varchar(100), @cod varchar(20), 
		@gestiune varchar(20), @codProdus varchar(80), @backCount int,
		@comandaNoua bit /* la comanda noua trimit atributul wmDateTerti.cod cu nr comenzii generat */, 
		@actiune varchar(30) /* stabilesc actiunea: back, sau autoSelect  */, @clearSearch bit, --pentru stergere camp de search,
		@cantitate decimal(12,3),@pret decimal(12,3), @discount decimal(12,2), @input XML, @data datetime

select	@comanda=rtrim(@parXML.value('(/row/@wmDetTerti.cod)[1]','varchar(20)')),
		@cod=@parXML.value('(/row/@wmComandaTertDeschisa.cod)[1]','varchar(20)'),
		@codProdus=@parXML.value('(/row/@wmComandaTertDeschisaHandler.cod)[1]','varchar(20)'), -- aici se insereaza cod prin wmNomenclator
		@clearSearch=0, @comandaNoua=0, 
		@backCount=( case when @codProdus is null then 1/*implicit*/ else 2/*s-a ales cod cu wmNomenclator si apoi macheta document*/ end), 
		@actiune='back('+CONVERT(varchar, @backCount)+')'

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

--citire date din par
select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end)
from par
where Tip_parametru='GE' and Parametru ='SUBPRO'

if @cod='<NOU>' -- adaugare produs nou
begin
	-- verific daca nu s-a scanat un cod de bare in zona 'searchText' se va adauga in comanda curenta 
	-- -> cred ca va cauza probleme cand cauta manual un produs
	declare @codcitit varchar(100), @codScanat varchar(100)
	select	@codcitit=rtrim(@parXML.value('(/row/@searchText)[1]','varchar(100)')),
			@codcitit=REPLACE(@codcitit,'CipherLab','')

	if len(isnull(@codcitit,''))>0
	begin
		--il cautam in tabela de coduri de bare  
		select @codScanat=rtrim(cb.Cod_produs) from codbare cb where cb.Cod_de_bare=@codcitit
		--il cautam si in nomenclator -> dezactivat pt. ca adauga produse ala'ndala
		--if @codScanat is null  
		--	select @codScanat=cod from nomencl where cod=@codcitit
		   
		if @codScanat is not null --inseamna ca am gasit cod scanat
		begin  
			set @actiune='autoSelect' -- autoselectez prima linie din wmNomenclator
			if @parXML.value('(/row/@codExact)[1]', 'varchar(20)') is not null             
				set @parXML.modify('replace value of (/row/@codExact)[1] with sql:variable("@codScanat")')                       
			else             
				set @parXML.modify ('insert attribute codExact{sql:variable("@codScanat")} into (/row)[1]')
			if @parXML.value('(/row/@searchText)[1]', 'varchar(200)') is not null                  
				set @parXML.modify ('delete (/row/@searchText)[1]') 
		end
	end  

	if @codProdus is null -- e null daca inca nu s-a  ales un cod cu proc. wmNomenclator
	begin
		-- citesc discount acordat tertului si il sugerez
		set @discount=isnull((select Disccount_acordat from terti where tert=@tert),0)
		if @parXML.value('(/row/@discount)[1]', 'varchar(200)') is not null                  
			set @parXML.modify('replace value of (/row/@discount)[1] with sql:variable("@discount")')
		else
			set @parXML.modify ('insert attribute discount{sql:variable("@discount")} into (/row)[1]') 
		
		-- adaug linie noua in pe comanda
		if @parXML.value('(/row/@faradetalii)[1]', 'varchar(200)') is not null                  
			set @parXML.modify('replace value of (/row/@faradetalii)[1] with "1"')
		else
			set @parXML.modify ('insert attribute faradetalii{"1"} into (/row)[1]') 
		exec wmNomenclator @sesiune,@parXML
		
		select 'wmComandaTertDeschisaHandler' as detalii,1 as areSearch, 'Comanda:'+@comanda as titlu , 
			'D' as tipdetalii, (case when @codScanat is not null then 'autoSelect' else null end) as actiune,
			(case when @codScanat is not null then 1 else null end) as clearSearch,
			(select datafield as '@datafield',nume as '@nume',tipobiect as '@tipobiect',latime as '@latime',modificabil as '@modificabil'  
			from webConfigForm where tipmacheta='M' and meniu='MD' and vizibil=1   
			order by ordine  
			for xml path('row'), type) as 'form'  
		for xml raw,Root('Mesaje')  

		return
	end
	else
	begin
		-- daca este @codProdus, a s-a ales cod nou folosind wmNomenclator
		select	@cod=@codProdus
		
		if @parXML.value('(/row/@wmComandaTertDeschisaHandler.cod)[1]', 'varchar(200)') is not null                  
			set @parXML.modify ('delete (/row/@wmComandaTertDeschisaHandler.cod)[1]') 
		if @parXML.value('(/row/@wmComandaTertDeschisa.cod)[1]', 'varchar(200)') is not null                  
			set @parXML.modify('replace value of (/row/@wmComandaTertDeschisa.cod)[1] with sql:variable("@cod")')
		else           
			set @parXML.modify ('insert attribute wmComandaTertDeschisa.cod {sql:variable("@cod")} into (/row)[1]') 
	end
end

if @cod='<INC>'
begin
	--Se inchide comanda prin schimbarea starii
	update con set Stare='1'
		where Subunitate=@subunitate and tip='BK 'and contract=@comanda and Stare='0' and tert=@tert and Punct_livrare=@idPunctLivrare

	select 'back(1)' as actiune
	for xml raw,root('Mesaje')
	return
end

-- citesc date din antet comanda
select @gestiune = c.Gestiune, @data=c.Data from con c where c.Subunitate=@subunitate and c.Tip='BK' and c.Contract=@comanda and Punct_livrare=@idPunctLivrare

select	@cantitate=@parXML.value('(/row/@cantitate)[1]','decimal(12,3)'),
		@pret=@parXML.value('(/row/@pret)[1]','decimal(12,3)'),
		@discount=@parXML.value('(/row/@discount)[1]','decimal(12,2)')
if not exists ( select 1 from pozcon pc where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda and pc.Cod=@cod )
begin
	set @input=(select @subunitate as '@subunitate','BK' as '@tip',rtrim(@comanda) as '@numar',rtrim(@gestiune) as '@gestiune',
					rtrim(@tert) as '@tert', convert(char(10),@data,101) as '@data', @idpunctlivrare as '@punctlivrare',
					(select @cod as '@cod',convert(char(10),convert(decimal(12,3),isnull(@cantitate,1))) as '@cantitate',isnull(@discount,0) as '@discount' for xml Path,type)
				for xml Path,type)
	exec wScriuPozCon @sesiune,@input
end
else
begin
	if @cantitate=0
		delete from pozcon
		where Subunitate=@subunitate and tip='BK' and tert=@tert and contract=@comanda and cod=@cod

	update pozcon set Cantitate=(case when @cantitate is null then Cantitate else @cantitate end),
		pret=(case when @pret is null then pret else @pret end), discount=(case when @discount is null then discount else @discount end)
	where Subunitate=@subunitate and tip='BK' and tert=@tert and contract=@comanda and cod=@cod
end

 
select @actiune actiune
	--, @parXML 'parxmlnou'
for xml raw,Root('Mesaje')
