--***
create procedure wmIaTerti @sesiune varchar(50), @parXML xml as  
set transaction isolation level READ UNCOMMITTED  
if exists(select * from sysobjects where name='wmIaTertiSP' and type='P')  
begin
	exec wmIaTertiSP @sesiune, @parXML   
	return 0
end

declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @valuta varchar(3),   
	@caFurn int, @caBenef int, @inValuta int, @userASiS varchar(10), @lista_clienti bit,@faradetalii int,
	@arelm varchar(20), @rasp varchar(max), @procDetalii varchar(100),@ruta varchar(20), @tertExact varchar(20)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  
select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@searchText=REPLACE(@searchText, ' ', '%'),
		@faradetalii=ISNULL(@parXML.value('(/row/@faradetalii)[1]', 'int'), 0),
		@ruta=ISNULL(@parXML.value('(/row/@ruta)[1]', 'varchar(20)'), ''),
		@tertExact=ISNULL(@parXML.value('(/row/@tertExact)[1]', 'varchar(20)'), ''),
		
		/* e bine sa pastram prefixul wmIaTerti, pt. ca sa nu apara 
		probleme cand se apeleaza mai multe proceduri de acest fel*/
		@procDetalii= @parXML.value('(/row/@wmIaTerti.procdetalii)[1]', 'varchar(100)')

declare @utilizator varchar(20)
exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator output
if @utilizator is null 
	return -1

if (select count(*) from proprietati where tip='UTILIZATOR' and Cod_proprietate='LOCMUNCAF' and cod=@utilizator)>0
	set @arelm=1
else
	set @arelm=0

IF OBJECT_ID('tempdb..#terti') IS NOT NULL  
	drop table #terti  

-- creare tabela temporara pentru adunarea tertilor
create table #terti(id int identity, tert varchar(50), identificator varchar(50), denumire varchar(150), 
	info varchar(150), procdetalii varchar(100))
CREATE NONCLUSTERED INDEX ix_tertIdentificator ON #terti(tert, identificator)


insert #terti(tert, identificator, denumire, info)
select top 25
	rtrim(terti.tert) as tert,
	ISNULL(rtrim(it.identificator),'') as identificator,  
	rtrim(terti.denumire)as denumire,   
	isnull(rtrim(it.DESCRIERE),rtrim(terti.adresa)) as info
from terti   
left join infotert itExt /*extensie terti*/ 
	on itExt.Subunitate=terti.Subunitate and itExt.Tert=terti.Tert 
	and itExt.identificator=''
left join infotert it /*puncte livrare*/ 
	on isnull(@parXML.value('(/row/@wmIaTerti.procdetalii)[1]', 'varchar(80)'),'')!='wmComandaAsistent' and 
		it.subunitate=terti.Subunitate and it.tert=terti.tert and 
		it.identificator<>''
where terti.subunitate=@subunitate
	and (terti.denumire+' '+isnull(it.DESCRIERE,'') like '%'+@searchText+'%' or terti.tert like @searchText+'%'
		or terti.Cod_fiscal like @searchText+'%')
	 and (itExt.Loc_munca is not null or it.Loc_munca is not null)
	 and (@ruta='' or it.banca3=@ruta)
	and (@arelm=0 or isnull(it.loc_munca,itExt.loc_munca) in (select valoare from proprietati pflm where pflm.tip='UTILIZATOR' and pflm.Cod_proprietate='LOCMUNCAF' and pflm.cod=@utilizator))
	and (NULLIF(@tertExact,'') IS NULL or terti.tert=@tertExact)
group by terti.tert,it.identificator,terti.denumire,it.DESCRIERE,terti.adresa
order by patindex('%'+@searchText+'%',terti.Denumire), terti.Denumire

if (select COUNT(1) from #terti)=25
begin 
	insert #terti(denumire, procdetalii)
	values('<Filtrati pt mai multi terti>', 'back(0)')
end


select t.tert as tert, ISNULL(rtrim(t.identificator),'') pctliv,
rtrim(t.denumire) as denumire,  
rtrim(t.info)/*+' (S='+convert(varchar(20),convert(money,isnull(s.sold,0),1))+')'*/ as info,
'000000' culoare, procdetalii procdetalii
from #terti t   
left join 
	(select sum(f.Sold) as sold, tt.tert, tt.identificator   
	  from facturi f inner join #terti tt on f.tert=tt.tert and tip=0x46  
		and (tt.identificator='' or exists (select 1 from incfact i where tt.identificator=i.Serie_doc  
		  and i.tert=f.tert and i.Numar_factura=f.factura))  
	 group by tt.tert, tt.identificator  
	) s on t.tert=s.tert and t.identificator=s.identificator  
order by t.id
for xml raw

IF NOT EXISTS (select 1 from #terti)
begin
	select
		'Adauga tert' denumire, 'Introducere cod fiscal' info, 'wmAdaugTert' procdetalii, 'D' tipdetalii, '0x0000ff' as culoare, 'assets/Imagini/Meniu/AdaugProdus32.png' as poza,
		dbo.f_wmIaForm('ADT') form
	for xml raw
end


IF OBJECT_ID('tempdb..#terti') IS NOT NULL  
	drop table #terti  

if (1 = @@NESTLEVEL)
	select '@searchText' as atribute for xml raw('atributeRelevante'),root('Mesaje')

if @faradetalii=0 
	select isnull(@procDetalii,'wmDetTerti') as detalii,1 as areSearch, 1 toateAtr, 2 as _campuriRelevante
	for xml raw,Root('Mesaje')

IF NULLIF(@tertExact ,'') IS NOT NULL
BEGIN
	select @tertExact setSearch for xml raw, root('Mesaje')
	select '' tertExact for xml raw('atribute'), root('Mesaje')
END
