--***
create procedure wIaCosturiSql (@sesiune varchar(50), @parXML xml)
as
declare @eroare varchar(500)
set @eroare=''
begin try
	declare --@data datetime, 
			@valmax decimal(13,3),
			@datajos datetime, @datasus datetime, @locm varchar(20), @comanda varchar(50),
			@denlocm varchar(50), @dencomanda varchar(100),
			@valoareJos decimal(13,3), @valoareSus decimal(13,3),
			@tip_comanda varchar(100),@rezolvat varchar(100),
			@f_grupare varchar(500)
	declare @utilizator varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator
	set @valmax=9999999999.999
	select	--@data=@parxml.value('(row/@data)[1]','datetime'),
			@datajos=@parxml.value('(row/@datajos)[1]','datetime')
			,@datasus=@parxml.value('(row/@datasus)[1]','datetime')
			,@locm=isnull(@parxml.value('(row/@locm)[1]','varchar(20)'),'')+'%'
			,@denlocm='%'+isnull(@parxml.value('(row/@denLocm)[1]','varchar(20)'),'')+'%'
			,@comanda=isnull(@parxml.value('(row/@comanda)[1]','varchar(50)'),'%')
			,@tip_comanda=@parxml.value('(row/@tip_comanda)[1]','varchar(50)')
			,@rezolvat=@parxml.value('(row/@rezolvat)[1]','varchar(50)')
			,@dencomanda='%'+isnull(@parxml.value('(row/@denComanda)[1]','varchar(50)'),'')+'%'
			,@f_grupare=isnull(@parxml.value('(row/@f_grupare)[1]','varchar(100)'),'')
			,@valoareJos=isnull(@parxml.value('(row/@valoareJos)[1]','decimal(13,3)'),-@valmax)
			,@valoareSus=isnull(@parxml.value('(row/@valoareSus)[1]','decimal(13,3)'),@valmax)
			
	select top 100
		(case when q.comanda!='' then 'Com.'+rtrim(q.comanda) when q.lm!='' then 'RL '+rtrim(q.lm) else 'RG' end) as grupare
		, convert(varchar(20),q.data,101) data, rtrim(q.lm) lm, rtrim(q.comanda) comanda
		, convert(decimal(20,3),q.costuri) costuri, convert(decimal(20,3),q.cantitate) cantitate
		, convert(decimal(20,3),q.pret) pret, q.rezolvat
		, rtrim(c.Descriere) as dencomanda, rtrim(c.tip_comanda) as tipcomanda, rtrim(lm.Denumire) as denlm
		, case when q.rezolvat=0 then '#FF0000' else null end as culoare
		,isnull(p.nr_pozitii,0) as nrpozitii
	from costurisql q
		left join comenzi c on q.comanda=c.comanda
		left join lm on q.lm=lm.Cod
		outer apply(select count(*) as nr_pozitii from costsql cs where cs.LM_SUP=q.lm and cs.COMANDA_SUP=q.comanda and cs.art_sup not in ('P','R','N') and cs.data between @datajos and @datasus) p
	where data between @datajos and @datasus and
		(@locm='%' or q.lm like @locm)
		and (@comanda='%' or q.comanda like rtrim(@comanda)+'%')
		and (isnull(lm.Denumire,'') like @denlocm) and (isnull(c.Descriere,'') like @dencomanda)
		and	costuri between @valoareJos and @valoareSus
		and ((dbo.denTipComanda(c.tip_comanda) like '%'+@tip_comanda+'%' and len(@tip_comanda)>1) or c.Tip_comanda=@tip_comanda or isnull(@tip_comanda,'')='')
		and (isnull(@rezolvat,'')='' or (q.rezolvat=1 and @rezolvat='DA') or (q.rezolvat=0 and @rezolvat='NU'))
		and (rtrim(ltrim((case when q.comanda!='' then 'Com.'+rtrim(q.comanda) when q.lm!='' then 'RL '+rtrim(q.lm) else 'RG' end))) like @f_grupare+'%' or isnull(@f_grupare,'')='')--filtrare pe coloana grupare
	order by q.lm, q.comanda
	for xml raw
end try
begin catch
	set @eroare='wIaCosturiSql:'+char(10)+error_message()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
