--***
create procedure RefacereNcon @dataj datetime, @datas datetime, @tip char(2)='', @numar char(13)=''
as
 
declare @sub char(9), @docdef int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'DOCDEF', @docdef output, 0, ''

/*if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
	raiserror('RefacereNcon: Accesul este restrictionat pe anumite locuri de munca! Nu este 
		permisa refacerea in aceste conditii!',16,1)
	return
end*/

update ncon 
set nr_pozitii=0, valoare=0, valoare_valuta=0
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar=@numar) and data between @dataj and @datas 

insert into ncon 
(Subunitate, Tip, Numar, Data, Jurnal, Nr_pozitii, Valuta, Curs, Valoare, Valoare_valuta, Stare) 
select subunitate, tip, numar, data, 
min(jurnal), 0, min(valuta), min(curs), 0, 0, (case when @docdef=1 and right(min(utilizator), 1)='2' 
then 2 else 0 end) 
from pozncon p 
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar=@numar) and data between @dataj and @datas 
group by subunitate, tip, numar, data 
having not exists (select 1 from ncon n where n.subunitate=p.subunitate and n.tip=p.tip 
and n.numar=p.numar and n.data=p.data) 

select subunitate, tip, numar, data, 
sum(1) as nr_pozitii, sum(suma) as valoare, sum(suma_valuta) as valoare_valuta 
into #tmpncon 
from pozncon 
where subunitate=@sub and (RTrim(@tip)='' or tip=@tip) 
and (RTrim(@numar)='' or numar=@numar) and data between @dataj and @datas 
group by subunitate, tip, numar, data 

update ncon 
set nr_pozitii=ncon.nr_pozitii+tn.nr_pozitii, valoare=ncon.valoare+tn.valoare, 
valoare_valuta=ncon.valoare_valuta+tn.valoare_valuta 
from #tmpncon tn 
where ncon.subunitate=tn.subunitate and ncon.tip=tn.tip and ncon.numar=tn.numar 
and ncon.data=tn.data 

drop table #tmpncon 
