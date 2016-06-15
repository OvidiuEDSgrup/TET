--***  
/* afisare pozitii comanda deschisa pe tert */
CREATE procedure [dbo].[wmComandaTertDeschisa] @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmComandaTertDeschisaSP' and type='P')
begin
	exec wmComandaTertDeschisaSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @idPunctLivrare varchar(100),
		@comanda varchar(20), @explicatii varchar(100), @linietotal varchar(100), @data datetime,@cod varchar(20), 
		@gestiune varchar(20), @discountMinim decimal(12,2), @discountMaxim decimal(12,2), @pasDiscount decimal(12,2),
		@discount decimal(12,2),
		@comandaNoua bit /* la comanda noua trimit atributul wmDateTerti.cod cu nr comenzii generat */, 
		@actiune varchar(30) /* stabilesc actiunea in frame: refresh daca se adauga cu cod de bare,  */, @clearSearch bit --pentru stergere camp de search  

select	@clearSearch=0,
		@comandaNoua=0

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

-- citesc datele de numeric stepper pentru discount
exec wmIaDiscountAgent @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output

-- identificare comanda deschisa
set @comanda=rtrim(@parXML.value('(/row/@wmDetTerti.cod)[1]','varchar(20)'))  
if @comanda='<ComandaNoua>' 
begin 
	select top 1 @comanda=RTRIM(contract) 
	from con c
	where Subunitate=@subunitate and tip='BK' and tert=@tert and stare='0' and responsabil=@utilizator and c.Punct_livrare=@idPunctLivrare
	
	-- daca nu am gasit comanda, creez antetul si mai incerc o data
	if @comanda='<ComandaNoua>'
	begin
		exec wmScriuAntetComanda @sesiune, @parXML
		
		select top 1 @comanda=RTRIM(contract)
		from con c
		where Subunitate=@subunitate and tip='BK' and tert=@tert and stare='0' and responsabil=@utilizator and c.Punct_livrare=@idPunctLivrare
		
		if @comanda='<ComandaNoua>'
		begin -- nu prea se ajunge aici...
			raiserror('(wmComandaTertDeschisa)Nu pot crea o comanda noua!',11,1)
			return -1
		end
	end
	
	-- salvez codul comenzii in xml
	set @comandaNoua=1
	if @parXML.value('(/row/@wmDetTerti.cod)[1]', 'varchar(20)') is not null                    
		set @parXML.modify('replace value of (/row/@wmDetTerti.cod)[1] with sql:variable("@comanda")')                       
	else             
		set @parXML.modify ('insert attribute wmDetTerti.cod{sql:variable("@comanda")} into (/row)[1]')
end
if not exists (select 1 from con c where Subunitate=@subunitate and 
	tip='BK' and tert=@tert and stare='0' and responsabil=@utilizator and c.Punct_livrare=@idPunctLivrare)
begin -- nu prea se ajunge aici...
	raiserror('(wmComandaTertDeschisa)Comanda nu poate fi identificata!',11,1)
	return -1
end

-- sterg atribute care se completeaza in procedura apelata dupa aceasta
if @parXML.value('(/row/@wmComandaTertDeschisaHandler.cod)[1]', 'varchar(200)') is not null                  
	set @parXML.modify ('delete (/row/@wmComandaTertDeschisaHandler.cod)[1]') 

-- citesc date antet
select top 1 @explicatii=explicatii,@tert=tert,@data=data  
from con where Subunitate=@subunitate and tip='BK' and Contract=@comanda and Responsabil=@utilizator  

-- actualizare data comenzi, daca e primul cod adaugat pe comanda, pt. ca sa nu fie data 
if not exists (select 1 from pozcon pc where Subunitate=@subunitate and tip='BK' and tert=@tert and Contract=@comanda)
	update con set Data=CONVERT(datetime,convert(varchar,getdate(),101),101)
	where Subunitate=@subunitate and tip='BK' and Contract=@comanda and Responsabil=@utilizator  

select @linietotal=LTRIM(str(count(pc.cantitate)))+' art: '+rTRIM(convert(char(20),convert(decimal(12,2),(sum(pc.Cantitate*pc.Pret*(1-pc.discount/100))))))+' LEI'   
from pozcon pc  
where Subunitate=@subunitate and tip='BK' and tert=@tert and Contract=@comanda  

select 2 as ord,rtrim(pc.cod) as cod, 
	rtrim(n.Denumire) as denumire,   
	LTRIM(convert(char(10),(convert(decimal(12,2),pc.Cantitate))))+' '+n.um+'*'  
		+RTRIM(convert(char(20),(convert(decimal(12,2),pc.Pret))))+' LEI'+  
	(case when pc.discount<>0 then '(-'+LTRIM(str(convert(decimal(12,2),pc.discount)))+'%)' else '' end)  
	as info, '0xffffff' as culoare, null as actiune,
	convert(decimal(12,3),pc.cantitate) as cantitate, convert(decimal(12,3),pc.pret) as pret, convert(decimal(12,2),pc.discount) as discount,
	'D' as tipdetalii, @discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas,
	null as poza
from pozcon pc  
left outer join nomencl n on pc.Cod=n.Cod  
where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda and pc.Tert=@tert
union all  
select 3 as ord,'<NOU>' as cod, 
	'<Aleg cod>' as denumire,
	'' as info,'0x0000ff' as culoare, null as actiune,
	0 as cantitate,0 as pret, null as discount, 
	'C' as tipdetalii ,@discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas,
	'assets/Imagini/Meniu/Populare.png' as poza
union all
select 1 as ord,'<INC>' as cod,  
'Inchide comanda' as denumire,
@linietotal as info,'0x000000' as culoare, 'refresh' as actiune,
0 as cantitate,0 as pret, null as discount,
'C' as tipdetalii, @discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas,
'assets/Imagini/Meniu/Realizari.png' as poza
where @linietotal is not null
order by 1,2
for xml raw    
 
select 'wmComandaTertDeschisaHandler' as detalii,0 as areSearch, 'Comanda:'+@comanda as titlu , @actiune actiune,
	'D' as tipdetalii, 
	(select datafield as '@datafield',nume as '@nume',tipobiect as '@tipobiect',latime as '@latime',modificabil as '@modificabil'  
	from webConfigForm where tipmacheta='M' and meniu='MD' and vizibil=1   
	order by ordine  
	for xml path('row'), type) as 'form',
	@parXML as 'parxmlnou'
	--(select @comanda '@wmIaComenzi.cod' for xml path('parxmlnou'), type) --as 'parxmlnou'
for xml raw,Root('Mesaje')
