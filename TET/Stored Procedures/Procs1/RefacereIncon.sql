--***
create procedure RefacereIncon @dataj datetime, @datas datetime
as
 
declare @sub char(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

/*if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
	raiserror('RefacereIncon: Accesul este restrictionat pe anumite locuri de munca! Nu este 
		permisa refacerea in aceste conditii!',16,1)
	return
end*/

update incon 
set numar_pozitie=0 
where subunitate=@sub and data between @dataj and @datas 

insert into incon
(Subunitate, Tip_document, Numar_document, Data, Jurnal, Numar_pozitie) 
select Subunitate, Tip_document, Numar_document, Data, Jurnal, 0 
from pozincon p 
where subunitate=@sub and data between @dataj and @datas 
group by Subunitate, Tip_document, Numar_document, Data, Jurnal 
having not exists (select 1 from incon i where i.subunitate=p.subunitate 
and i.tip_document=p.tip_document and i.numar_document=p.numar_document and i.data=p.data 
and i.jurnal=p.jurnal) 

select Subunitate, Tip_document, Numar_document, Data, Jurnal, sum(1) as numar_pozitie 
into #tmpincon
from pozincon 
where subunitate=@sub and data between @dataj and @datas 
group by Subunitate, Tip_document, Numar_document, Data, Jurnal 

update incon 
set numar_pozitie=incon.numar_pozitie+ti.numar_pozitie 
from #tmpincon ti 
where incon.subunitate=ti.subunitate and incon.tip_document=ti.tip_document 
and incon.numar_document=ti.numar_document and incon.data=ti.data and incon.jurnal=ti.jurnal 

drop table #tmpincon
