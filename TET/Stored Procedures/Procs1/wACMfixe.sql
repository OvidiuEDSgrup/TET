--***
Create procedure wACMfixe @sesiune varchar(50), @parXML XML
as

declare @sub varchar(9), @userASiS varchar(10), @searchText varchar(100), @datal datetime, @luna int, @an int,
	@tip varchar(2), @update int, @bugetari int, @dinRapoarte bit
--select @sub=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE','BUGETARI', @bugetari output, 0, ''
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select @datal=xa.row.value('@datal', 'datetime'),
	@tip=xa.row.value('@tip', 'varchar(2)'),
	@dinRapoarte=(case when xa.row.value('@raport', 'varchar(100)') is null then 0 else 1 end)
from @parXML.nodes('row') as xa(row)

if @datal is null 
begin
	select	@luna=xa.row.value('@luna', 'int'),
			@an=xa.row.value('@an', 'int')
	from @parXML.nodes('row') as xa(row)
	if nullif(@luna,0) is not null and nullif(@an,0) is not null
		set @datal=dbo.EOM(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	else
		set @datal=dbo.EOM(getdate())
end
if @tip is null set @tip=''
set @update=isnull(@parXML.value('(/row/row/@update)[1]','int'),0)

select top 100 rtrim(m.Numar_de_inventar) as cod, (case when @tip in ('MM','ME') then 
	'Ct.m.f.'+RTRIM(isnull(f1.Cont_mijloc_fix, f1a.Cont_mijloc_fix))+
	',ct.am.'+RTRIM(f1.Cont_amortizare)+','+
	ltrim(CONVERT(varchar(20), convert(decimal(15, 0), isnull(f1.Durata, f1a.Durata))))+' ani,'+
	ltrim(CONVERT(varchar(20), convert(decimal(15, 0), isnull(f1.Numar_de_luni_pana_la_am_int, 
	f1a.Numar_de_luni_pana_la_am_int-(case when f1a.Numar_de_luni_pana_la_am_int<=0 then 0 else 1 end)))))+' luni ramase' 
		else 'Gest.'+RTRIM(isnull(f1.Gestiune, f1a.Gestiune))+',l.m.'+
	RTRIM(isnull(f1.Loc_de_munca,f1a.Loc_de_munca))+',com.'+RTRIM(left(isnull(f1.Comanda, f1a.Comanda),
	20))+(case when @bugetari=1 then ',ind.bug.'+
	isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),1,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),3,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),5,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),7,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),9,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),11,2),'  ')+'.'
	+isnull(substring(substring(isnull(f1.comanda,f1a.comanda),21,20),13,2),'  ') else '' end) end) 
	as info, rtrim(m.denumire) as denumire
from MFix m 
	left outer join MFix md on md.Subunitate='DENS' and md.Numar_de_inventar=m.Numar_de_inventar
	left outer join fisaMF f1 on f1.Subunitate=m.Subunitate and 
		f1.Data_lunii_operatiei=@datal and f1.Felul_operatiei='1' and 
		f1.Numar_de_inventar=m.Numar_de_inventar
	left outer join fisaMF f1a on f1a.Subunitate=m.Subunitate and 
		f1a.Data_lunii_operatiei=dbo.bom(@datal)-1 and f1a.Felul_operatiei='1' and 
		f1a.Numar_de_inventar=m.Numar_de_inventar
	left outer join LMFiltrare lu on lu.utilizator=@userASiS 
		and lu.cod=isnull(f1.Loc_de_munca, f1a.Loc_de_munca)
--left outer join LMFiltrare l1a on l1m.utilizator=@userASiS and f1a.Loc_de_munca=l1m.cod
where m.subunitate=@sub 
	and dbo.eom(m.Data_punerii_in_functiune)<=@datal --and m.felul_operatiei='1' 
	and (m.Numar_de_inventar like @searchText+'%' or m.denumire like '%'+@searchText+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null /*or lu.cod is null and l1m.cod is not 
		null */)
	and (@update=1 or @dinRapoarte=1 or not exists (select 1 from misMF mm where mm.Subunitate=m.Subunitate 
		and left(mm.Tip_miscare,1)='E' and mm.Numar_de_inventar=m.Numar_de_inventar and mm.Data_lunii_de_miscare<dbo.bom(@datal)))
order by m.Numar_de_inventar
for xml raw
