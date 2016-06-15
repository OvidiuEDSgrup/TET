--***
create procedure rapRegistruJurnal (@Valuta varchar(40)=null, @DataJos datetime, @DataSus datetime, 
			@TipDocumente varchar(1)=null,
			@TipConturi varchar(1)=1,	--> 1=de bilant, 2=in afara bilantului, 3=toate
			@Centralizare varchar(1)=1, @ordonare int=1, @locm varchar(20)=null,
			--> pt raport CGplus:
			@utilizator varchar(20)=null, @jurnal varchar(20)=null,
			--> urmatorii parametri ar trebui analizati daca merita sau nu sa mai existe:
			@pasmatex bit=0, @libNoi bit=0, @IFN bit=0, @inValuta bit=0,
			@sumecumulate bit=0	--> 0=sumele cumulate apar doar la reportat;
								--	1=sumele cumulate apar pe fiecare linie
			,@indicator varchar(100)=null	--> indicator bugetar
			) as
begin
--exec fainregistraricontabile @datasus=@DataSus
set transaction isolation level read uncommitted
select @utilizator=isnull(@utilizator,''), @jurnal=isnull(@jurnal,'')
if @Valuta is null or @Valuta='RON' set @Valuta=''
if @TipDocumente is null set @TipDocumente='T'

select @indicator=@indicator+'%'

declare @utilizatorSesiune varchar(20), @eLmUtiliz int
select @utilizatorSesiune=dbo.fIaUtilizator('')
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
select l.cod from lmfiltrare l where l.utilizator=@utilizatorSesiune
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

declare @filtrareLM int, @epsilon decimal(5,5), @subunitate varchar(20)
select @filtrareLM=(case when @locm is null or @locm='%' or @locm='' then 0 else 1 end), @locm=@locm+'%',
	@epsilon=0.01,
	@subunitate=(select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO')

IF OBJECT_ID('tempdb..#grupate') IS NOT NULL drop table #grupate
IF OBJECT_ID('tempdb..#date') IS NOT NULL drop table #date

--select c.data c.Curs from curs c where @IFN=1 and p.valuta<>'' and c.valuta=p.valuta and c.data=dbo.eom(p.data)

select rtrim(Subunitate) Subunitate, rtrim(Tip_document) Tip_document, 
		(case 
			when tip_document='PI' and len(rtrim(explicatii))-len(replace(rtrim(explicatii),' ',''))>=2 and explicatii not like 'N:%' then substring(explicatii,4,CHARINDEX(' ',explicatii,CHARINDEX(' ',explicatii,1)+1)-3) 
			when tip_document='PI' and explicatii like 'N:%' and CHARINDEX(',',explicatii)>5 then substring(explicatii,6,CHARINDEX(',',explicatii)-6)
			else numar_document end) as numar_document, 
	p.Data, rtrim(Cont_debitor) Cont_debitor, rtrim(Cont_creditor) Cont_creditor, 
	(case when @inValuta=1 then p.Suma_valuta when @IFN=1 and @Valuta='' and abs(round(convert(decimal(18, 5), p.suma), 2))<@epsilon and p.valuta<>'' then p.Suma_valuta*isnull(c.curs, 1) else p.Suma end)
	Suma, rtrim(p.Valuta) Valuta, p.Curs Curs, 
	rtrim(Explicatii) Explicatii, rtrim(Utilizator) Utilizator, Data_operarii, rtrim(Ora_operarii) Ora_operarii, 
	rtrim(Numar_pozitie) Numar_pozitie, rtrim(Loc_de_munca) Loc_de_munca, rtrim(Comanda) Comanda, 
	(case when RTrim(Cont_debitor)='' then 0 else Suma/(case when rtrim(@Valuta)<>'' and p.curs<>0 then p.Curs else 1 end) end) as suma_debit, 
	(case when RTrim(Cont_creditor)='' then 0 else Suma/(case when rtrim(@Valuta)<>'' and p.curs<>0 then p.Curs else 1 end) end) as suma_credit,
	p.Jurnal,
	p.Suma_valuta
into #date
from pozincon p
	left outer join curs c on @IFN=1 and 
		abs(round(convert(decimal(18, 5), p.suma), 2))<@epsilon and 
		p.valuta<>'' and c.valuta=p.valuta and year(c.data)=year(p.data) and month(c.data)=month(p.data)
    where Subunitate=@subunitate
      and p.Data between @DataJos and @DataSus and abs(suma)>0.0075
      and (@TipDocumente='T'
      OR
      (@TipDocumente='P' AND (Tip_document='PI' or (@pasmatex=1 and Tip_document in ('CO','C3','CF','CB'))) and not (@libNoi=1 and Tip_document='PI' and cont_debitor like '413%'))
      OR
      (@TipDocumente='F' AND Tip_document in ('RM','RS','FF','SF'))
      OR
      (@TipDocumente='B' AND Tip_document in ('AP','AC','AS','FB','IF'))
      OR
      (@TipDocumente='A' AND (Tip_document NOT IN ('PI','RM','RS','FF','SF','AP','AC','AS','FB','IF') and not (@pasmatex=1 and Tip_document in ('CO','C3','CF','CB')) or  (@libNoi=1 and Tip_document='PI' and cont_debitor like '413%'))
      ))
      and p.valuta like rtrim(@Valuta)+'%'
      and (@TipConturi='1' and not (left(cont_debitor,1)>='8' or left(cont_creditor,1)>='8') or @TipConturi='2' and (left(cont_debitor,1)>='8' or left(cont_creditor,1)>='8') or @TipConturi='3')
      and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=Loc_de_munca))
      and (@filtrareLM=0 or loc_de_munca like @locm)
      and (@utilizator='' or p.Utilizator=@utilizator)
      and (@jurnal='' or p.Jurnal=@jurnal)--*/
      and (@indicator is null or p.indbug like @indicator)
--/*

if OBJECT_ID('rapRegistruJurnalSP') is not null
begin
	declare @xml xml
	set @xml = (select @valuta valuta, convert(char(10), @DataJos,101) DataJos, convert(char(10), @DataSus,101) DataSus, 
						@TipDocumente TipDocumente, @TipConturi TipConturi, @Centralizare Centralizare, @ordonare ordonare, @locm locm, 
						@utilizator utilizator, @jurnal jurnal, @pasmatex pasmatex, @libNoi libNoi, @IFN IFN, @inValuta inValuta, @sumecumulate sumecumulate, 
						@indicator indicator for xml raw)
	exec rapRegistruJurnalSP @parXML=@xml
end

create table #grupate(randul int, Subunitate varchar(20), Tip_document varchar(2), Numar_document varchar(20), Data datetime, Cont_debitor varchar(40),
	Cont_creditor varchar(40), Suma decimal(15,2), Valuta varchar(20), Curs decimal(15,5), Explicatii varchar(200), Utilizator varchar(20),
	Data_operarii datetime,	Ora_operarii varchar(6), Numar_pozitie int, Loc_de_munca varchar(20), Comanda varchar(40),
	suma_debit decimal(15,3), suma_credit decimal(15,3), suma_debit_cumulat decimal(15,3), suma_credit_cumulat decimal(15,3),
	ordonare varchar(300), jurnal varchar(3), Suma_valuta decimal(15,5))

if (@Centralizare=1)
insert into #grupate(randul, Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Explicatii, Utilizator,
		Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, suma_debit, suma_credit, suma_debit_cumulat, suma_credit_cumulat,
		ordonare, jurnal, Suma_valuta)
select --row_number() over (order by Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, numar_pozitie) as randul,
	0 as randul,
	Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Explicatii,
	Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, suma_debit, suma_credit,
	suma_debit suma_debit_cumulat, suma_credit suma_credit_cumulat,
	(case @ordonare when 2 then convert(varchar(20),data,102) when 3 then Cont_debitor+'|'+Cont_creditor
			when 4 then Subunitate+Cont_debitor+Cont_creditor when 5 then Subunitate+convert(char(10),d.Data,102)+Numar_document
		else '' end)
		--+'|'+Tip_document+'|'+Numar_document+'|'+convert(varchar(20),data,102)+'|'+Cont_debitor+'|'+Cont_creditor+'|'+convert(varchar(20),numar_pozitie)
	as ordonare, d.jurnal, d.Suma_valuta
from #date d --where @Centralizare=1

if (@Centralizare=2)
insert into #grupate(randul, Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Explicatii, Utilizator,
		Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, suma_debit, suma_credit, suma_debit_cumulat, suma_credit_cumulat,
		ordonare, jurnal, Suma_valuta)
select --row_number() over (order by Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor) as randul,
	0 as randul,
	max(Subunitate) as Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, sum(Suma) Suma, 
	max(Valuta) Valuta, avg(Curs) Curs, max(Explicatii) Explicatii,
	max(Utilizator) Utilizator, max(Data_operarii) Data_operarii, max(Ora_operarii) Ora_operarii, '1' Numar_pozitie, 
	max(Loc_de_munca) Loc_de_munca, max(Comanda) Comanda, sum(suma_debit) suma_debit, sum(suma_credit) suma_credit,
	sum(suma_debit) suma_debit_cumulat, sum(suma_debit) suma_credit_cumulat,
	(case @ordonare when 2 then convert(varchar(20),data,102) when 3 then Cont_debitor+'|'+Cont_creditor else '' end)
	--+Tip_document+'|'+Numar_document+'|'+convert(varchar(20),data,102)+'|'+Cont_debitor+'|'+Cont_creditor
	as ordonare,
	'' jurnal, sum(Suma_valuta)
from #date-- where @Centralizare=2
group by Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor

if (@Centralizare=3)
insert into #grupate(randul, Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Explicatii, Utilizator,
		Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, suma_debit, suma_credit, suma_debit_cumulat, suma_credit_cumulat,
		ordonare, jurnal, Suma_valuta)
select --row_number() over (order by Cont_debitor, Cont_creditor ) as randul,
	0 as randul,
	max(Subunitate) as Subunitate, '' Tip_document, '' Numar_document, '1901-1-1' Data, 
	Cont_debitor, Cont_creditor, sum(Suma) Suma, 
	max(Valuta) Valuta, avg(Curs) Curs, max(Explicatii) Explicatii,
	max(Utilizator) Utilizator, max(Data_operarii) Data_operarii, max(Ora_operarii) Ora_operarii, '1' Numar_pozitie, 
	max(Loc_de_munca) Loc_de_munca, max(Comanda) Comanda, sum(suma_debit) suma_debit, sum(suma_credit) suma_credit,
	sum(suma_debit) suma_debit_cumulat, sum(suma_debit) suma_credit_cumulat,
	Cont_debitor+'|'+Cont_creditor as ordonare, '' jurnal, sum(Suma_valuta)
from #date --where @Centralizare=3
group by Cont_debitor, Cont_creditor 
order by Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Numar_pozitie

create clustered index indx on #grupate (ordonare, Tip_document, Numar_document, data, Cont_debitor, Cont_creditor,numar_pozitie)

declare @cumulat_credit decimal(15,3), @cumulat_debit decimal(15,3)
select @cumulat_credit=0, @cumulat_debit=0

update g		--< metoda de calcul rapid al "runningvalue" (cumularii); ordinea e stabilita mai sus de index-ul clustered "nrrnd"
set @cumulat_credit=g.suma_credit_cumulat=@cumulat_credit+g.suma_credit_cumulat,
	@cumulat_debit=g.suma_debit_cumulat=@cumulat_debit+g.suma_debit_cumulat
from #grupate g

select Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma,
/*	p.Valuta, p.Curs, p.suma_valuta, 
	Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda	*/

	Explicatii,
	Utilizator, Jurnal, Loc_de_munca, Comanda, Numar_pozitie, Data_operarii, Ora_operarii, Valuta, Curs, suma_valuta,--> pana aici campurile comune cu ASIS
	(case when @sumecumulate=0 then suma_debit else suma_debit_cumulat end) suma_debit,
	(case when @sumecumulate=0 then suma_credit else suma_credit_cumulat end) suma_credit,
	suma_debit_cumulat, suma_credit_cumulat
	from #grupate order by randul

--select * from #date
IF OBJECT_ID('tempdb..#grupate') IS NOT NULL drop table #grupate
IF OBJECT_ID('tempdb..#date') IS NOT NULL drop table #date
--order by (case when @Centralizare='3' then Subunitate+Cont_debitor+Cont_creditor else Subunitate+convert(char(10),Data,102)+Tip_document+Numar_document+Cont_debitor+Cont_creditor end)
end
