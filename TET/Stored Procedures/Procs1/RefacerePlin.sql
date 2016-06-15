--***
create procedure RefacerePlin @dataj datetime,@datas datetime,@jurnal char(3)='',@cont varchar(40)=''
as

declare @sub char(9), @docdef int, @nrantPI int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'DOCDEF', @docdef output, 0, ''
exec luare_date_par 'GE', 'NRANTPI', @nrantPI output, 0, ''

/*if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
	raiserror('RefacerePlin: Accesul este restrictionat pe anumite locuri de munca! Nu este 
		permisa refacerea in aceste conditii!',16,1)
	return
end*/

update plin 
set total_plati=0, total_incasari=0, numar_pozitii=0 
where subunitate=@sub and data between @dataj and @datas 
and (RTrim(@jurnal)='' or jurnal=@jurnal) 
and (RTrim(@cont)='' or cont=@cont) 

insert into plin 
(Subunitate, Cont, Data, Numar, Valuta, Curs, Total_plati, Total_incasari, Ziua, Numar_pozitii, Jurnal, Stare) 
select subunitate, cont, data, 
left(min(numar),8), min(valuta), min(curs), 0, 0, 
max(datepart(day, data)), 0, jurnal, (case when @docdef=1 and right(min(utilizator), 1)='2' then 2 else 0 end) 
from pozplin pp 
where subunitate=@sub and data between @dataj and @datas 
and (RTrim(@jurnal)='' or jurnal=@jurnal) and (RTrim(@cont)='' or cont=@cont) 
group by subunitate, cont, data, jurnal 
having not exists (select 1 from plin p where p.subunitate=pp.subunitate and p.cont=pp.cont and p.data=pp.data and p.jurnal=pp.jurnal) 

select subunitate, cont, data, jurnal, sum(1) as numar_pozitii, 
sum(case when left(plata_incasare, 1)='P' then suma else 0 end) as total_plati, 
sum(case when left(plata_incasare, 1)='P' then 0 else suma end) as total_incasari,
max(numar) as numar
into #tmpplin 
from pozplin 
where subunitate=@sub and data between @dataj and @datas 
and (RTrim(@jurnal)='' or jurnal=@jurnal) and (RTrim(@cont)='' or cont=@cont) 
group by subunitate, cont, data, jurnal 

update plin 
set numar_pozitii = plin.numar_pozitii + tp.numar_pozitii, 
total_plati=plin.total_plati + tp.total_plati, 
total_incasari=plin.total_incasari + tp.total_incasari, 
numar=(case when @nrantPI=1 then plin.numar else tp.numar end)
from #tmpplin tp 
where tp.subunitate=plin.subunitate and tp.cont=plin.cont and tp.data=plin.data and tp.jurnal=plin.jurnal 

drop table #tmpplin 
