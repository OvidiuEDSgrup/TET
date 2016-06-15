CREATE PROCEDURE FacturiPeConturi @sesiune VARCHAR(50), @parXML XML output
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @factura VARCHAR(20), @mesaj VARCHAR(400), @tipOperatiune VARCHAR(2), @utilizator varchar(50), 
		@valuta varchar(3), @sub varchar(9), @bugetari int, @facturiPeConturi int, @parXMLFact xml 
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati 
	EXEC luare_date_par 'GE', 'BUGETARI', @bugetari OUTPUT, 0, '' --> citire specific bugetari din parametrii

	SET @tipOperatiune = isnull(@parXML.value('(/*/*/@tipOperatiune)[1]', 'varchar(2)'),'') 
	SET @tert = isnull(@parXML.value('(/*/*/@tert)[1]', 'varchar(20)'),'')
	SET @factura = nullif(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'),'')
	SET @valuta = isnull(@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)'),'')

	set @facturiPeConturi=0

	if object_id('tempdb..#tmpfacturiPeConturi') is not null drop table #tmpfacturiPeConturi

	/*	Daca bugetari, verificam daca exista mai multe conturi/mai multi indicatori bugetari pe o factura. 
		Si nu doar bugetari: la PF nu ar trebui sa dureze, iar pe partea de beneficiari doar daca s-a ales o factura.*/
	if @bugetari=1 or @tipOperatiune='PF' or @tipOperatiune='IB' --and @factura is not null	--Permis si la IB chiar daca nu s-a ales o factura (SNC are cazuri).
	begin
		/* se preia in tabela #docfacturi prin procedura pFacturi, in locul functiei fFacturi */
		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'

		set @parXMLFact=(select (case when @tipOperatiune='IB' then 'B' else 'F' end) as furnbenef, rtrim(@tert) as tert, rtrim(@factura) as factura for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		if exists (select 1 from #docfacturi group by tert, factura having count(distinct cont_de_tert)>1 or count(distinct indbug)>1 or count(distinct loc_de_munca)>1)
		begin
			set @facturiPeConturi=1
			select f.tert,f.factura,max(f.Data) as data_factura,max(f.Data_scadentei) as Data_scadentei,
				sum(case when isnull(f.Valuta,'')<>'' then f.total_valuta-f.achitat_valuta else f.valoare+f.tva-f.achitat end) as sold,max(f.loc_de_munca) as loc_de_munca,
				max(f.comanda) as comanda,max(f.valuta) as valuta,max(f.curs) as curs, 
				sum(case when isnull(f.Valuta,'')<>'' then f.total_valuta else f.valoare end) as valoare,
				sum(f.tva) as tva_22, f.cont_de_tert, f.indbug, 0 as nr_cont_fact
			into #tmpfacturiPeConturi
			from #docfacturi f 
			where (f.Valuta=@valuta or (f.Valuta='' and isnull(@valuta,'')='')) 
				and not (@tipOperatiune='IB' and f.cont_de_tert like '418') 
				and not (@tipOperatiune='PF' and f.cont_de_tert like '408')
			group by f.tert, f.factura, f.cont_de_tert, f.indbug, f.loc_de_munca
			/*	nu fac aici filtrarea pentru ca pot fi plati partiale care au stins un anumite cont/loc de munca/indicator. 
				La plati urmatoare pe aceleasi facturi trebuie sa intre tot prin macheta de plati/incasari facturi selectiva. Se sterg soldurile nule mai jos */
			--having (abs(sum(f.total_valuta-f.achitat_valuta))>0.001 or (max(f.Valuta)='' and abs(sum(f.valoare+f.tva-f.achitat))>0.001))

			update fc 
				set fc.nr_cont_fact=(case when ni.nr_cont_fact>1 then ni.nr_cont_fact when ni.nr_lm_fact>1 then ni.nr_lm_fact when ni.nr_ind_fact>1 then ni.nr_ind_fact else 1 end)
			from #tmpfacturiPeConturi fc
				left outer join (select tert, factura, count(distinct cont_de_tert) as nr_cont_fact, count(distinct loc_de_munca) as nr_lm_fact, count(distinct indbug) as nr_ind_fact 
					from #tmpfacturiPeConturi fc1 group by tert, factura) ni on ni.tert=fc.tert and ni.factura=fc.factura
			delete from #tmpFacturiPeConturi where not(abs(sold)>0.001)	--	aici se sterg soldurile la care se facea referire mai sus */

			/*	sterg si facturile cu sold 0 la nivel de tert + factura */
			delete t from #tmpFacturiPeConturi t 
			where exists (select 1 from #tmpFacturiPeConturi t1 where t1.tert=t.tert and t1.factura=t.factura group by t1.tert, t1.factura having convert(decimal(12,2),abs(sum(sold)))<0.01)
		end
	end

	if @facturiPeConturi=1 
	begin
		if object_id('tempdb..#facturiPeConturi') is not null 
			insert into #facturiPeConturi 
				(tert, factura, data_factura, Data_scadentei, sold, loc_de_munca, comanda, valuta, curs, valoare, tva_22, cont_de_tert, indbug, nr_cont_fact)
			select f.tert, f.factura, f.data_factura, f.Data_scadentei, f.sold, f.loc_de_munca, f.comanda, f.valuta, f.curs, 
				f.valoare, f.tva_22, f.cont_de_tert, f.indbug, f.nr_cont_fact
			from #tmpfacturiPeConturi f
		else 
			select f.tert, f.factura, f.data_factura, f.Data_scadentei, f.sold, f.loc_de_munca, f.comanda, f.valuta, f.curs, 
				f.valoare, f.tva_22, f.cont_de_tert, f.indbug, f.nr_cont_fact
			from #tmpfacturiPeConturi f
	end
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	RAISERROR (@mesaj, 11, 1)
END CATCH
/*
select * from facturi
*/
