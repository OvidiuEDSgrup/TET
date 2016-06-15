--***
create procedure rapMonografieContabila (@datajos datetime=null, @datasus datetime=null, @tipDocumente varchar(2)=null, @contDebitor varchar(40)=null, @contCreditor varchar(40)=null)
as
if object_id('tempdb..#dindoc') is not null drop table #dindoc
if object_id('tempdb..#pozincon') is not null drop table #pozincon
if object_id('tempdb..#identificator') is not null drop table #identificator
if object_id('tempdb..#filtruConturi') is not null drop table #filtruConturi
declare @eroare varchar(2000)
begin try
	--exec fainregistraricontabile @datasus=@datasus
	set transaction isolation level read uncommitted
	declare @f_datajos bit, @f_datasus bit, @f_tipDocumente bit, @f_contDebitor bit, @f_contCreditor bit
	select	@f_datajos=(case when @datajos is null then 0 else 1 end),
			@f_datasus=(case when @datasus is null then 0 else 1 end),
			@f_tipDocumente=(case when @tipDocumente is null then 0 else 1 end),
			@f_contDebitor=(case when @contDebitor is null then 0 else 1 end),
			@f_contCreditor=(case when @contCreditor is null then 0 else 1 end),
			@contDebitor=rtrim(@contDebitor)+'%',
			@contCreditor=rtrim(@contCreditor)+'%'
	
	--> filtrare, grupare si selectare din pozincon a datelor necesare raportului (de fapt aici se unifica liniile cu acelasi numar de document si combinatie de conturi):
	select tip_document, cont_debitor, cont_creditor, numar_document,sum(p.Suma) as suma into #pozincon from pozincon p
		where (@f_tipDocumente=0 or p.Tip_document=@tipDocumente)
			and (@f_datajos=0 or p.Data>=@datajos) and (@f_datasus=0 or p.Data<=@datasus)
	group by tip_document, cont_debitor, cont_creditor, numar_document
	--> se filtreaza si pe conturi:
	select distinct p.tip_document, p.numar_document into #filtruConturi from #pozincon p where (@f_contDebitor=0 or p.Cont_debitor like @contDebitor) and (@f_contCreditor=0 or p.Cont_creditor like @contCreditor)
	
	--> ordonare a documentelor si a combinatiilor distincte de conturi pentru a se putea lua o singura data fiecare monografie:
	create table #dindoc(tip_document varchar(2), ordineDoc int, ordineInDoc int, cont_debitor varchar(40), cont_creditor varchar(40),
		numar_document varchar(40), suma decimal(15,3), masca varchar(max), mascaGata int, nrLiniiDoc int)

	insert into #dindoc(tip_document, ordineDoc, ordineInDoc, cont_debitor, cont_creditor, numar_document, suma, masca, mascaGata, nrLiniiDoc)
	select	p.tip_document,
		dense_rank() over (order by p.numar_document, p.tip_document) as ordineDoc,	--> ordonarea documentelor
		row_number()
		over (partition by p.numar_document, p.tip_document order by p.cont_debitor, p.cont_creditor) as ordineInDoc,	--> ordonarea datelor in cadrul documentelor
		p.cont_debitor, p.cont_creditor, p.numar_document, p.suma, rtrim(p.cont_debitor)+'--'+rtrim(p.cont_creditor), -1,
		(case when (@f_contDebitor=0 or p.Cont_debitor like @contDebitor) and (@f_contCreditor=0 or p.Cont_creditor like @contCreditor) then 0 else -1 end)
	from #pozincon p inner join #filtruConturi f on p.tip_document=f.tip_document and p.numar_document=f.numar_document
	create clustered index ordine on #dindoc(ordineDoc,cont_debitor, cont_creditor, ordineInDoc)

	-->	identificarea documentelor pe monografii:
		--	se compune cate o masca pentru fiecare monografie si pentru fiecare document;
			--	nrLiniiDoc semnaleaza documentele care contin conturile pe care se filtreaza prin comparatie cu mascaGata
	declare @masca varchar(max), @monografie int, @mascaGata int

	select @masca='', @monografie=0, @mascaGata=0
	update f set @masca=masca=(case when f.ordineDoc=@monografie then rtrim(@masca)+'|'+rtrim(masca) else '|'+rtrim(masca) end),
				@mascaGata=f.mascaGata=(case when f.ordineDoc=@monografie then @mascaGata+f.mascaGata else f.mascaGata end),
				@monografie=f.ordineDoc from #dindoc f

		-- se semnaleaza mastile completate (pentru fiecare document)
	select max(len(rtrim(masca))) as lMaxMasca, f.ordineDoc into #identificator from #dindoc f
		group by ordineDoc
	update d set nrLiniiDoc=abs(mascaGata), mascaGata=0 from #dindoc d inner join #identificator i on d.ordineDoc=i.ordineDoc
		where len(rtrim(d.masca))=i.lMaxMasca

	--> selectarea datelor finale: cate un document pentru fiecare monografie
	select count(1), max(d.tip_document) tip_document, max(d.ordineDoc) ordineDoc, max(d.Numar_document) numar_document, d.cont_debitor, d.cont_creditor,
		count(1)/convert(float,max(d1.nrLiniiDoc)) cateDoc,
		sum(d.suma) as suma
	from #dindoc d inner join (select distinct ordinedoc, masca, nrLiniiDoc, tip_document from #dindoc d1 where d1.mascaGata=0) d1
		on d1.ordineDoc=d.ordineDoc
	group by d1.tip_document, d1.masca, d.Cont_debitor, d.Cont_creditor
	order by d1.tip_document, max(d1.ordineDoc), d.Cont_debitor, d.Cont_creditor
end try
begin catch
	select @eroare=ERROR_MESSAGE()+' (rapMonografieContabila - '+convert(varchar(20),error_line())+')'
end catch

if object_id('tempdb..#dindoc') is not null drop table #dindoc
if object_id('tempdb..#pozincon') is not null drop table #pozincon
if object_id('tempdb..#identificator') is not null drop table #identificator
if object_id('tempdb..#filtruConturi') is not null drop table #filtruConturi
if len(@eroare)>0 raiserror(@eroare,16,1)
