--***
create procedure wIaDeconturi @sesiune varchar(50), @parXML xml
as

declare @Sub char(9), @userASiS varchar(10), @lista_lm bit, @lista_conturi bit, @DecGrCont int, 
	@tip varchar(2), @cont varchar(40), @fcont varchar(40), @data_jos datetime, @data_sus datetime, @data datetime, 
	@tplati_jos float, @tplati_sus float, @tinc_jos float, @tinc_sus float, @marca varchar(6), @decont varchar(40), @fnume varchar(50),
	@tert varchar(13),@efect varchar(20),@fdentert varchar(80),@fdencont varchar(80), @flm varchar(50),@f_cont_corespondent varchar(13)
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'DECMARCT', @DecGrCont output, 0, ''

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
select @lista_lm=dbo.f_arelmfiltru(@userASiS), @lista_conturi=0
if exists (select 1 from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CONTPLIN' and valoare<>'')
	set @lista_conturi=1

if object_id('tempdb..#decalculat') is not null drop table #decalculat
if object_id('tempdb..#pozincon_debit') is not null drop table #pozincon_debit
if object_id('tempdb..#pozincon_credit') is not null drop table #pozincon_credit
if object_id('tempdb..#fltdec') is not null drop table #fltdec
if object_id('tempdb..#test') is not null drop table #test

select @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@cont = isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''), 
	--@tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	--@efect = ISNULL(@parXML.value('(/row/@efect)[1]','varchar(20)'), ''),
	@fcont = isnull(@parXML.value('(/row/@f_cont)[1]', 'varchar(40)'), ''), 
	@marca = isnull(@parXML.value('(/row/@marca)[1]', 'varchar(6)'), ''), 
	@decont = isnull(@parXML.value('(/row/@decont)[1]', 'varchar(40)'), ''), 
	@flm = ISNULL(@parXML.value('(/row/@f_lm)[1]', 'varchar(9)'),''),
	@fnume = isnull(@parXML.value('(/row/@f_nume)[1]', 'varchar(50)'), '%'), 
	@fdentert = isnull(@parXML.value('(/row/@f_dentert)[1]', 'varchar(80)'),''), 
	@fdencont = isnull(@parXML.value('(/row/@f_dencont)[1]', 'varchar(80)'),''), 
	@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
	@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '12/31/2999'), 
	@data = @parXML.value('(/row/@data)[1]', 'datetime'), 
	@tplati_jos = isnull(@parXML.value('(/row/@f_tplatijos)[1]', 'float'), -99999999999),
	@tplati_sus = isnull(@parXML.value('(/row/@f_tplatisus)[1]', 'float'), 99999999999), 
	@tinc_jos = isnull(@parXML.value('(/row/@f_tincjos)[1]', 'float'), -99999999999),
	@tinc_sus = isnull(@parXML.value('(/row/@f_tincsus)[1]', 'float'), 99999999999), 
	@f_cont_corespondent = isnull(@parXML.value('(/row/@f_cont_corespondent)[1]', 'varchar(13)'), '')

select top 100
	rtrim(p.subunitate) as subunitate, @tip tip,
	rtrim(p.cont) as cont, rtrim(max(isnull(c.denumire_cont, ''))) as dencont, 
	convert(char(10), p.data, 101) as data, 
	(case when rtrim(max(p.valuta))='' and max(isnull(pr.valoare,''))<>'' then max(isnull(pr.valoare,'')) else rtrim(max(p.valuta)) end) as valuta, 
	convert(decimal(15,4), max(p.curs)) as curs, 
	rtrim(p.marca) as marca, 
	rtrim(max(isnull(pers.nume, ''))) as denmarca, 
	rtrim(max(case when @DecGrCont=1 then p.cont else isnull(p.decont, p.numar) end)) as decont, 
	sum(convert(decimal(15,2), (case when left(p.plata_incasare, 1)='P' then p.suma else 0 end))) as totalplati, 
	sum(convert(decimal(15,2),(case when left(p.plata_incasare, 1)='P' then (case when p.valuta='' then 0 else p.suma_valuta end) else 0 end))) as totalplativaluta, 
	sum(convert(decimal(15,2), (case when left(p.plata_incasare, 1)='I' then p.suma else 0 end))) as totalincasari, 
	sum(convert(decimal(15,2), (case when left(p.plata_incasare, 1)='I' then (case when p.valuta='' then 0 else p.suma_valuta end) else 0 end))) as totalincasarivaluta,

	sum(p.suma) suma,
	sum(case when left(p.Plata_incasare,1)='I' then p.suma else -p.suma end) as total,

	convert(decimal(15,2),0) totalsold, 
	convert(decimal(15,2),0) soldinitial,
	convert(decimal(15,2),0) soldinitialvaluta,
	convert(decimal(15,2),0) rulajdebit,
	convert(decimal(15,2),0) rulajcredit,
	convert(decimal(15,2),0) soldfinal,
	convert(decimal(15,2),0) soldfinalvaluta,
	convert(decimal(15,2),0) rulajdebitvaluta,
	convert(decimal(15,2),0) rulajcreditvaluta,
	sum(1) as numarpozitii,
		
	--pentru tabul de inregistrari contabile:
	'PI' tipdocument,rtrim(p.Cont) as 'nrdocument'
into #decalculat
from pozplin p
	left outer join conturi c on c.subunitate = p.subunitate and c.cont = p.cont 
	left outer join personal pers on pers.marca=p.marca
	left outer join proprietati pr on pr.tip='CONT' and pr.cod=p.cont and pr.cod_proprietate='INVALUTA'
where p.subunitate=@Sub
	and not (p.Plata_incasare in ('PF','IB') and p.efect is not null) -- sa nu aduca date de pozplin legate de efecte - acestea sunt tratate in wIaEfecte
	and isnull(c.sold_credit, 0)=9 --and @tip in ('DE','DR') 
	and (@cont='' or p.cont=@cont) and p.cont like @fcont + '%'
	and (@marca='' or p.marca=@marca) 
	and (@decont='' or p.decont=@decont)
	and (@fnume='%' or pers.Nume like '%'+@fnume+'%')
	and p.data between @data_jos and (case when @data_sus<='01/01/1901' then '12/31/2999' else @data_sus end)
	and (@data is null or p.data=@data) 
	and (@lista_lm=0 or /*lu.cod is not null*/ exists (select * from LMFiltrare lu where lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca ))
	and (@flm='' or p.loc_de_munca like @flm + '%')
	and (@lista_conturi=0 or exists (select 1 from proprietati lc where RTrim(p.cont) like RTrim(lc.valoare)+'%' and lc.tip='UTILIZATOR' and lc.cod=@userASiS and lc.cod_proprietate='CONTPLIN'))
	and (@fdencont='' or (c.Denumire_cont like '%'+replace(@fdencont,' ','%')+'%'))
	and (@f_cont_corespondent='' or p.Cont_corespondent like '%'+@f_cont_corespondent+'%')
group by p.subunitate, p.cont, p.data, --p.Valuta, 
	p.marca, (case when @DecGrCont=1 then p.cont else isnull(p.decont, p.numar) end)
-- Ghita: Oare sunt necesare astea de mai jos?	
/*having sum(convert(decimal(15,2), (case when left(p.plata_incasare, 1)='P' and p.plata_incasare<>'PS' then p.suma else 0 end))) between @tplati_jos and @tplati_sus
	and sum(convert(decimal(15,2), (case when left(p.plata_incasare, 1)='I' and p.plata_incasare<>'IS' then p.suma else 0 end))) between @tinc_jos and @tinc_sus
*/
order by p.cont, p.data desc

--> calcul sold initial:
declare @parXMLDec xml
set @parXMLDec=(select @data_sus as datasus, nullif(@marca,'') as marca, nullif(@decont,'') as decont, 1 as grmarca, 1 as grdec, 1 as cen for xml raw)
/* completez deconturile in tabela temporara #fltdec, pentru a putea calcula in pDeconturi soldul doar pt. deconturile afisate */
select distinct data, marca, decont, cont into #fltdec from #decalculat
if object_id('tempdb..#pdeconturi') is not null 
	drop table #pdeconturi
create table #pdeconturi (subunitate varchar(9))
if 1=0 -- asa ar fi riguros, dar dureaza - trebuie optimizat
begin
	exec CreazaDiezDeconturi @numeTabela='#pdeconturi'
	exec pDeconturi @sesiune=@sesiune, @parxml=@parXMLDec
end
else -- asa merge repede, dar ia soldurile la zi, nu la data decontarii 
begin
	alter table #pdeconturi
		add Marca char(6), Decont varchar(40), Cont varchar(40), --Data datetime, Data_scadentei datetime, Valoare float, Valuta char(3), Curs float, 
			--Valoare_valuta float, Decontat float, 
			Sold float, --Decontat_valuta float, 
			Sold_valuta float--, Loc_de_munca char(9), Comanda char(40), Data_ultimei_decontari datetime 
	insert #pdeconturi
		select @sub, d.marca, d.decont, d.cont, d.sold, d.sold_valuta from deconturi d inner join #fltdec f on f.marca=d.marca and f.decont=d.decont 
end
		
--> inlocuire totaluri cu cele in valuta
update p set
	totalincasari=totalincasarivaluta, totalplati=totalplativaluta  
	from #decalculat p
	where p.valuta<>''

update p set 
	soldinitial=convert(decimal(15,3), (case when p.valuta='' then d.Sold else d.Sold_valuta end) -- din soldul final 
		- (convert(decimal(15,2), (case when p.valuta='' then p.total else p.totalincasari-p.totalplati end)))) -- se scade rulajul
from #decalculat p
	left outer join #pdeconturi d on d.Marca=p.Marca and d.Decont=p.Decont and d.Cont=p.Cont
		
/*update p set soldinitial=convert(decimal(15,3), dbo.solddec (p.data, p.marca,p.decont, p.cont) 
			- (convert(decimal(15,2), p.total)))
from #decalculat p*/

-->	calcul solduri finale:
update p set
	soldfinal=soldinitial+totalincasari-totalplati
	from #decalculat p
	
select subunitate, @tip tip, cont, dencont, data, valuta, curs, marca, denmarca, decont, 
	totalplati, totalplativaluta, totalincasari, totalincasarivaluta, totalsold, soldinitial, 
	soldinitialvaluta, rulajdebit, rulajcredit, soldfinal, soldfinalvaluta, numarpozitii, tipdocument, nrdocument
from #decalculat p
order by cont, convert(datetime, data) desc 
for xml raw

if object_id('tempdb..#pozincon') is not null drop table #pozincon
if object_id('tempdb..#pozincon_debit') is not null drop table #pozincon_debit
if object_id('tempdb..#pozincon_credit') is not null drop table #pozincon_credit
if object_id('tempdb..#fltdec') is not null drop table #fltdec
if object_id('tempdb..#test') is not null 
begin
	select * from #test 
	drop table #test
end
