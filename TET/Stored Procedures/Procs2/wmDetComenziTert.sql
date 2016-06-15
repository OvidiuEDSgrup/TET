--***  
/* handler comenzi pe tert */
CREATE procedure [dbo].[wmDetComenziTert] @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmDetComenziTertSP' and type='P')
begin
	exec wmDetComenziTertSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @idPunctLivrare varchar(100), 
		@comanda varchar(20), @explicatii varchar(100), @linietotal varchar(100), @data datetime,@cod varchar(20), 
		@clearSearch int --pentru stergere camp de search  
set @clearSearch=0  

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

select	@subunitate=rtrim(Val_alfanumerica)
from par where Tip_parametru='GE' and Parametru ='SUBPRO'

-- identificare comanda deschisa
set @comanda=rtrim(@parXML.value('(/row/@wmDateTerti.cod)[1]','varchar(20)'))  
if @comanda='<ComandaNoua>' 
begin 
	select top 1 @comanda=RTRIM(contract) 
	from con c
	where Subunitate=@subunitate and tip='BK' and tert=@tert and stare='0' and responsabil=@utilizator and c.Punct_livrare=@idPunctLivrare
	
	-- daca nu am gasit comanda, creez antetul si mai incerc o data
	if @comanda='<ComandaNoua>'
	begin
		exec wmScriuAntetComanda @sesiune, @parxml
		
		select top 1 @comanda=RTRIM(contract) 
		from con c
		where Subunitate=@subunitate and tip='BK' and tert=@tert and stare='0' and responsabil=@utilizator and c.Punct_livrare=@idPunctLivrare
		
		if @comanda='<ComandaNoua>'
		begin -- nu prea se ajunge aici...
			raiserror('(wmComandaDeschisa)Nu pot crea o comanda noua!',11,1)
			return -1
		end
	end
end

--daca se scaneaza un cod de bare produs se va adauga in comanda curenta  

declare @codcitit varchar(100)  
select	@cod=null,
		@codcitit=rtrim(@parXML.value('(/row/@searchText)[1]','varchar(100)')),
		@codcitit=REPLACE(@codcitit,'CipherLab','')  
   
--il cautam in tabela de coduri de bare  
select @cod=cb.Cod_produs from codbare cb where cb.Cod_de_bare=@codcitit and @codcitit!=''  
   
--il cautam si in nomenclator  
if @cod is null  
	select @cod=cod from nomencl where cod=@codcitit and @codcitit!=''  
   
if @cod is not null --inseamna ca l-am gasit  
begin  
	if @parXML.value('(/row/@wmAlegCantitateComenzi.cod)[1]', 'varchar(20)') is not null                    
		set @parXML.modify('replace value of (/row/@wmAlegCantitateComenzi.cod)[1] with sql:variable("@cod")')                       
	else             
		set @parXML.modify ('insert attribute wmAlegCantitateComenzi.cod{sql:variable("@cod")} into (/row)[1]')   
	if @parXML.value('(/row/@faradetalii)[1]', 'int') is not null                    
		set @parXML.modify('replace value of (/row/@faradetalii.cod)[1] with 1')                       
	else             
		set @parXML.modify ('insert attribute faradetalii{1} into (/row)[1]')   
      
	set @clearSearch=1 -- se sterge campul de search  
	exec wmScriuPozitieComanda @sesiune,@parXML  
end  

select top 1 @explicatii=explicatii,@tert=tert,@data=data  
from con where Subunitate=@subunitate and tip='BK' and Contract=@comanda and Responsabil=@utilizator  

select @linietotal=LTRIM(str(count(pc.cantitate)))+' art: '+rTRIM(convert(char(20),convert(decimal(12,2),(sum(pc.Cantitate*pc.Pret*(1-pc.discount/100))))))+' LEI'   
from pozcon pc  
where Subunitate=@subunitate and tip='BK'  and tert=@tert and Contract=@comanda  
             
 select top 100 2 as ord,rtrim(pc.cod) as cod,
 rtrim(n.Denumire) as denumire,   
 LTRIM(convert(char(10),(convert(decimal(12,2),pc.Cantitate))))+' '+n.um+'*'  
  +RTRIM(convert(char(20),(convert(decimal(12,2),pc.Pret))))+' LEI'+  
  (case when pc.discount<>0 then '(-'+LTRIM(str(convert(decimal(12,2),pc.discount)))+'%)' else '' end)  
  as info,  
 '0xffffff' as culoare,  
 convert(decimal(12,3),pc.cantitate) as cantitate,convert(decimal(12,3),pc.pret) as pret,  
 'D' as tipdetalii,'0' as discountmin, 50 as discountmax, 5 as discountpas  
 from pozcon pc  
 left outer join nomencl n on pc.Cod=n.Cod  
 where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda  
 union all  
 select top 100 3 as ord,'<NOU>' as cod,   
 '<Aleg cod>' as denumire,   
 '' as info,'0x0000ff' as culoare,  
 0 as cantitate,0 as pret,  
 'C' as tipdetalii ,'0' as discountmin, 50 as discountmax, 5 as discountpas  
 union all
 select top 100 1 as ord,'<INC>' as cod, 
	rtrim(@explicatii) as denumire,
	@linietotal as info,'0x000000' as culoare,
	0 as cantitate,0 as pret,
	'C' as tipdetalii, '0' as discountmin, 50 as discountmax, 5 as discountpas
	where @linietotal is not null
	order by 1,2
 for xml raw    
 
 select 'wmScriuCantitate' as detalii,0 as areSearch, 'Comanda:'+@comanda as titlu 
 ,'D' as tipdetalii,  
 (select datafield as '@datafield',nume as '@nume',tipobiect as '@tipobiect',latime as '@latime',modificabil as '@modificabil'  
  from webConfigForm where tipmacheta='M' and meniu='MD'  
  and vizibil=1   
  order by ordine  
  for xml path('row'), type) as 'form'  
 for xml raw,Root('Mesaje')
