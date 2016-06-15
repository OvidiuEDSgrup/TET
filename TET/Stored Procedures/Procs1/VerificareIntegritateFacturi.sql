--***
create procedure VerificareIntegritateFacturi 
	@dataJ datetime,
	@dataS datetime,
	@cuModificare int=0	/*Daca este 1 se vor modifica documentele, modificand numarul facturii*/
as
/* Aceasta procedura compara rezultatul rularii fTerti cu tabela facturi pentru a vedea daca
exista linii in fTerti grupat pe tert si factura care au contul diferit in tabela facturi
sau in gruparea din fTerti*/
begin
	/*	--	parametri pentru teste:
		declare @dataJ datetime,@dataS datetime,@cuModificare int=0	/*Daca este 1 se vor modifica documentele, modificand numarul facturii*/
		set @dataJ='01/01/1901'		set @dataS='12/31/2008'		set @cuModificare=1		--*/
	set transaction isolation level read uncommitted
	declare @eroare varchar(1000)
	set @eroare=''
	begin  try

		/*Ar trebui facuta tabela deoarece se foloseste si in fFacturiCen alte triggere sau cine stie pe unde*/
		CREATE TABLE #ordonaripetipuri(tip VARCHAR(2),ordine INT)
		INSERT INTO #ordonaripetipuri VALUES('RM',1)
		INSERT INTO #ordonaripetipuri VALUES('RS',2)
		INSERT INTO #ordonaripetipuri VALUES('FF',3)

		declare @areFacturiGresite int,@cSubunitate varchar(9),@parXMLFact xml
		set @cSubunitate=(select top 1 val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO')
		set @areFacturiGresite=0

		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		if object_id('tempdb..#facturi') is not null drop table #facturi

		/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'
		set @parXMLFact=(select '' as furnbenef, @dataJ as datajos, @dataS as datasus for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		create table #facturi (furn_benef char(1),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,cont_de_tert varchar(40))

		insert into #facturi
		select furn_benef,tert,factura,tip,numar,data,cont_de_tert
		from #docfacturi
		--from dbo.fFacturi('', @dataJ, @dataS, null, null, null, null, null, null, null, null)
		
		select furn_benef,tert,factura
		into #facturigresite
		from #facturi
		group by furn_benef,tert,factura
		having count(distinct cont_de_tert)>1

		if @@ROWCOUNT>0 /*Inseamna ca sunt facturi gresite care au pozitii pe mai multe conturi de terti*/
		begin
			set @areFacturiGresite=1
		end


		if @areFacturiGresite=1 and @cuModificare=0
			raiserror('Aveti necorelatii de cont intre documente si facturi',16,1)

		if @areFacturiGresite=1 and @cuModificare=1 
		if 1=0 -- pana se va forta SINGLE_MODE si se vor repune triggerele daca eroare 
			raiserror('Operatia este riscanta, vezi procedura VerificareIntegritateFacturi!',16,1)
		else
		begin
			select f1.tip,
				f1.numar,f1.data,f1.cont_de_tert,f1.tert,f1.factura,
				dense_RANK() over (partition by f1.tert,f1.factura order by f1.tert,f1.factura,ISNULL(o1.ordine,99),f1.cont_de_tert)
				as nrpoz
			into #docgresite
			from #facturi f1
				inner join #facturigresite f2 on f1.furn_benef=f2.furn_benef and f1.tert=f2.tert and f1.factura=f2.factura
				LEFT OUTER JOIN #ordonaripetipuri o1 on f1.tip=o1.tip
			group by f1.tip,f1.numar,f1.data,f1.cont_de_tert,f1.tert,f1.factura,ISNULL(o1.ordine,99)
			order by f1.tert,f1.factura,ISNULL(o1.ordine,99),f1.data,f1.cont_de_tert
	
			begin tran -- neaparat cu tranzactie -> avem clienti care au ramas in mod repetat doar cu aceste 2 triggere.
			
			--Aici trebuie avut grija de triggerele care sunt disable initial -> nu ne batem capul cu ele
			-- pozdoc
			alter table pozdoc disable trigger all
			alter table pozdoc enable trigger docFac
			alter table pozdoc enable trigger docFacAv

			update pozdoc set factura=rtrim(pozdoc.factura)+char(63+nrpoz)
			from pozdoc,#docgresite d 
			where pozdoc.subunitate=@cSubunitate and pozdoc.tip=d.tip and pozdoc.numar=d.numar and pozdoc.data=d.data 
			AND pozdoc.Cont_factura=d.cont_de_tert
			and d.nrpoz>1
			and d.tip in ('RM','RP','RS','AP','AS') AND LEN(RTRIM(d.factura))<20
			
			update pozdoc set cod_intrare=rtrim(pozdoc.cod_intrare)+char(63+nrpoz)
			from pozdoc,#docgresite d 
			where pozdoc.subunitate=@cSubunitate and pozdoc.tip=(CASE WHEN d.tip='RX' THEN 'RM' ELSE 'AP' end) 
				and pozdoc.numar=d.numar and pozdoc.data=d.data and pozdoc.Cont_de_stoc=d.cont_de_tert AND d.nrpoz>1
			and d.tip in ('RX','AX') AND LEN(RTRIM(d.factura))<20

			alter table pozdoc enable trigger all
			commit tran
			
			-- pozplin
			begin tran 
			alter table pozplin disable trigger all
			alter table pozplin enable trigger plinFac

			update pozplin set factura=rtrim(pozplin.factura)+char(63+nrpoz)
			from pozplin,#docgresite d 
			where pozplin.subunitate=@cSubunitate and pozplin.Plata_incasare=d.tip 
				and pozplin.tert=d.tert AND pozplin.factura=d.factura and pozplin.data=d.data and d.nrpoz>1
				AND pozplin.Cont_corespondent=d.cont_de_tert
				and d.tip in ('PF','PS','IB','IS') AND LEN(RTRIM(d.factura))<20

			alter table pozplin enable trigger all	
			commit tran

			-- pozadoc
			begin tran 
			alter table pozadoc disable trigger all
			alter table pozadoc enable trigger adocFacSt
			alter table pozadoc enable trigger adocFacDr

			update pozadoc set factura_stinga=rtrim(pozadoc.factura_stinga)+char(63+nrpoz)
			from pozadoc,#docgresite d 
			where pozadoc.subunitate=@cSubunitate and pozadoc.tip=d.tip 
				and pozadoc.tert=d.tert AND pozadoc.factura_stinga=d.factura and pozadoc.data=d.data and d.nrpoz>1
				AND pozadoc.Cont_deb=d.cont_de_tert
				and d.tip in ('FB','CB','IF','CO','CF','C3') AND LEN(RTRIM(d.factura))<20
			
			update pozadoc set Factura_dreapta=rtrim(pozadoc.Factura_dreapta)+char(63+nrpoz)
			from pozadoc,#docgresite d 
			where pozadoc.subunitate=@cSubunitate and pozadoc.tip=d.tip 
				and (case when d.tip='C3' then pozadoc.Tert_beneficiar else pozadoc.tert end)=d.tert 
				AND pozadoc.Factura_dreapta=d.factura and pozadoc.data=d.data and d.nrpoz>1
				AND pozadoc.Cont_cred=d.cont_de_tert
				and d.tip in ('FF','CF','SF','CO','CB','C3') AND LEN(RTRIM(d.factura))<20
			
			alter table pozadoc enable trigger all
			commit tran
		end

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		set @eroare=rtrim(ERROR_MESSAGE())+' ('+object_name(@@PROCID)+')'
	end catch
	
	IF OBJECT_ID('tempdb..#facturi') IS NOT NULL drop table #facturi
	IF OBJECT_ID('tempdb..#facturigresite') IS NOT NULL drop table #facturigresite
	IF OBJECT_ID('tempdb..#docgresite') IS NOT NULL drop table #docgresite
	IF OBJECT_ID('tempdb..#ordonaripetipuri') IS NOT NULL drop table #ordonaripetipuri

	if @eroare<>'' raiserror(@eroare,16,1)
end
