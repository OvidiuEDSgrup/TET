--***
create procedure RefacereAdoc @dataj datetime, @datas datetime, @tip char(2)='', @numar char(13)=''
as
 
declare @sub char(9), @docdef int, @docdefIE int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'DOCDEF', @docdef output, 0, ''
exec luare_date_par 'GE', 'DOCDEFIE', @docdefIE output, 0, ''

/*if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
	raiserror('RefacereAdoc: Accesul este restrictionat pe anumite locuri de munca! Nu este 
		permisa refacerea in aceste conditii!',16,1)
	return
end*/

update adoc set numar_pozitii=0 
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar_document=@numar) and data between @dataj and @datas 

insert into adoc 
(Subunitate, Tip, Numar_document, Data, Tert, Numar_pozitii, Jurnal, Stare) 
select subunitate, tip, numar_document, data, min(tert), 0, min(jurnal), max(case when stare=7 or @docdef=1 and @docdefIE=0 and stare=2 then stare else 0 end) 
from pozadoc pa 
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar_document=@numar) and data between @dataj and @datas 
group by subunitate, tip, numar_document, data 
having not exists (select 1 from adoc a where a.subunitate=pa.subunitate and a.tip=pa.tip and a.numar_document=pa.numar_document and a.data=pa.data) 

select subunitate, tip, numar_document, data, sum(1) as numar_pozitii 
into #tmpadoc 
from pozadoc 
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar_document=@numar) and data between @dataj and @datas 
group by subunitate, tip, numar_document, data 

update adoc 
set numar_pozitii=adoc.numar_pozitii+ta.numar_pozitii 
from #tmpadoc ta 
where ta.subunitate=adoc.subunitate and ta.tip=adoc.tip and ta.numar_document=adoc.numar_document and ta.data=adoc.data 

drop table #tmpadoc 
