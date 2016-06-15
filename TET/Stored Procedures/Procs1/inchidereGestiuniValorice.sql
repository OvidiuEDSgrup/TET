/*
	Exemplu rulare:
		declare @datalunii datetime='2015-01-31', @parXML xml
		set @parXML=(select convert(char(10),@datalunii,101) data, '1' as stergere, '1' as generare, 0 as optiunidescarcare for xml raw)
		EXEC inchidereGestiuniValorice @sesiune=NULL, @parXML=@parXML
		exec fainregistraricontabile @datasus=@datalunii

	Parametri specifici lucrului cu gestiuni valorice (toti parametri pe tip GE)
	Cont Adaos comercial
	Cont TVA neexigibil
	Cont venituri vanzare marfa
	Cont cheltuiala vanzare marfa

	@optDesc=0	Descarcare la vanzari cumulate
	@optDesc=1	Descarcare la vanzari lunare
	@optDesc=2	Descarcare la sold marfa

	Numere document
		- numerele de document sunt de forma DVLLAAAA in PoznCon

*/
create procedure inchidereGestiuniValorice @sesiune varchar(50), @parXML xml
as
begin try
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	declare 
		@data_lunii datetime, @bom_data_lunii datetime, @sub varchar(9), @utilizator varchar(20), @numar_doc varchar(8), @gestiune varchar(9), @gestiuneExceptata varchar(9), 
		@cotaTVA float, @contAdaos varchar(40), @contTvaNeexigil varchar(40), @DescFaraTVANeex int, @contVenitVanz varchar(40), @contCheltVanz varchar(40), @nr_pozitie int, 
		@stergere int, @generare int, @optDesc int, @calculKLaVanzariLunare int, @Dafora int, @Pragmatic int

	set @data_lunii=isnull(@parXML.value('(/*/@data)[1]','datetime'),'2999-01-01')
	set @stergere=isnull(@parXML.value('(/*/@stergere)[1]','int'),1)
	set @generare=isnull(@parXML.value('(/*/@generare)[1]','int'),1)
	set @optDesc=@parXML.value('(/*/@optiunidescarcare)[1]','int')
	set @gestiune=@parXML.value('(/*/@gestiune)[1]','varchar(9)')
	set @calculKLaVanzariLunare=@parXML.value('(/*/@calculKvanzarilunare)[1]','varchar(9)')

	select @data_lunii=dbo.eom(@data_lunii), @bom_data_lunii=dbo.bom(@data_lunii)
	
	/*	Citire parametrii specifici. */
	select @sub=RTRIM(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'
	select @cotaTVA=rtrim(val_numerica) from par where Tip_parametru='GE' and Parametru='COTATVA'
	if @cotaTVA is null
		set @cotaTVA=24
	select top 1 @contAdaos=rtrim(val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CADAOS'
	if @contAdaos is null
		set @contAdaos='378'
	select top 1 
		@contTvaNeexigil=rtrim(val_alfanumerica)
	from par where Tip_parametru='GE' and Parametru='CNTVA'
	if @contTvaNeexigil is null
		set @contTvaNeexigil='4428'
	select top 1 @DescFaraTVANeex=rtrim(val_logica) from par where Tip_parametru='GE' and Parametru='FARATVANE'
	set @DescFaraTVANeex=isnull(@DescFaraTVANeex,0)
	select top 1 @contVenitVanz=rtrim(val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CVMARFA'
	set @contVenitVanz='707'
	select top 1 @contCheltVanz=rtrim(val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCVMARFA'
	set @contCheltVanz='607'
	select top 1 @Dafora=rtrim(val_logica) from par where Tip_parametru='SP' and Parametru='DAFORA'
	select top 1 @Pragmatic=rtrim(val_logica) from par where Tip_parametru='GE' and Parametru='PRAGMATIC'
	select @Dafora=isnull(@Dafora,0), @Pragmatic=isnull(@Pragmatic,0)
	select top 1 @gestiuneExceptata=rtrim(val_alfanumerica) from par where Tip_parametru='GE' and Parametru='GEEXCEPT'
	if @optDesc is null
		select top 1 @optDesc=rtrim(val_numerica) from par where Tip_parametru='GE' and Parametru='NDESCGVAL'
	select @optDesc=isnull(@optDesc,0)
	if @calculKLaVanzariLunare is null
		select top 1 @calculKLaVanzariLunare=rtrim(Val_logica) from par where Tip_parametru='GE' and Parametru='NDESCGVAL'
	select @calculKLaVanzariLunare=isnull(@calculKLaVanzariLunare,0)

	select @utilizator=dbo.fIaUtilizator(null)
	if isnull(@utilizator,'')=''
		set @utilizator='DGESTVAL'

	select	
		@numar_doc = 'DV'+str(MONTH(@data_lunii),2)+convert(varchar(4), YEAR(@data_lunii))

	/* Stergere note contabile generate anterior. */
	delete from pozncon 
	where @stergere=1 and subunitate=@sub and tip='IC' and numar=@numar_doc and data between @bom_data_lunii and @data_lunii
			and (@gestiune is null or Cont_creditor='371.'+rtrim(@gestiune))
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data_lunii
	delete from DescVal
	/*	Citesc ultimul numar de pozitie scris in pozncon, daca se filtreaza descarcarea pe o gestiune. Sa se poata porni la scriere in pozncon de la acest numar (sa nu dea duplicate). */
	if nullif(@gestiune,'') is not null and @generare=1
		select @nr_pozitie=max(nr_pozitie) from pozncon 
		where subunitate=@sub and tip='IC' and numar=@numar_doc and data between @bom_data_lunii and @data_lunii
	set @nr_pozitie=isnull(@nr_pozitie,0)

	/* Generam descarcarea de gestiuni valorice in #DescVal */
	IF OBJECT_ID('tempdb..#venituri') IS NOT NULL
		DROP TABLE #venituri
	IF OBJECT_ID('tempdb..#conturi') IS NOT NULL
		DROP TABLE #conturi
	IF OBJECT_ID('tempdb..#RulajeCont') IS NOT NULL
		DROP TABLE #RulajeCont
	IF OBJECT_ID('tempdb..#DescVal') IS NOT NULL
		DROP TABLE #DescVal
	IF OBJECT_ID('tempdb..#ncon_dgv') IS NOT NULL
		DROP TABLE #ncon_dgv

	/*	Selectam sumele incasate pe conturile de venituri. */
	select cont707, sum(val_fara_tva+TVA11+TVA22) as Suma_incasata, sum(TVA11+TVA22) as TVA_incasat 
	into #venituri
	from
		(select cont_corespondent as cont707, sum(suma-TVA22) as val_fara_tva, 0 as TVA11, sum(TVA22) as TVA22
		from pozplin 
		where subunitate=@sub and data between @bom_data_lunii and @data_lunii and plata_incasare='IC' 
		and substring(cont_corespondent,5,9) in (select cod_gestiune from gestiuni where tip_gestiune='V') and cont_corespondent like '707.%'  
			and (@gestiuneExceptata is null or cont_corespondent <>  '707.'+rtrim(@gestiuneExceptata))
			and (@gestiune is null or cont_corespondent='707.'+rtrim(@gestiune))
		group by cont_corespondent
		union all 
		select cont_venituri, sum(cantitate*pret_vanzare), 0, sum(TVA_deductibil) 
		from pozdoc 
		where subunitate=@sub and data between @bom_data_lunii and @data_lunii
			and (tip='AP' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune='V') or tip='AS' 
			and substring(cont_venituri,5,9) in (select cod_gestiune from gestiuni where tip_gestiune='V')) and cont_venituri like '707.%'  
			and (@gestiuneExceptata is null or cont_venituri <> '707.'+rtrim(@gestiuneExceptata))
			and (@gestiune is null or cont_venituri='707.'+rtrim(@gestiune))
		group by cont_venituri 
		union all 
		select cont_cred, sum(suma), 0, sum(TVA22) 
		from pozadoc 
		where subunitate=@sub and data between @bom_data_lunii and @data_lunii and tip='FB' 
			and substring(cont_cred,5,9) in (select cod_gestiune from gestiuni where tip_gestiune='V') and cont_cred like '707.%'  
			and (@gestiuneExceptata is null or cont_cred <> '707.'+rtrim(@gestiuneExceptata))
			and (@gestiune is null or cont_cred='707.'+rtrim(@gestiune))
		group by cont_cred) a
	group by cont707
	
	alter table #venituri add gestiune varchar(9)
	update #venituri set gestiune=substring(cont707,charindex('.',rtrim(cont707))+1,20)

	/*	Stabilire prin tabela #conturi, a conturilor pentru care trebuie calculate Total sume/rulaje lunare. */
	select c.cont+'.'+rtrim(v.gestiune) as cont
	into #conturi
	from (select '371' as cont union all select @contAdaos union all select @contTvaNeexigil union all select '707') as c
	left join #venituri v on 1=1
	
	/*	Calcul Total sume/rulaje lunare. */
	select convert(varchar(4),'AN') as tipSuma, r.cont, sum(rulaj_debit) as suma_debit, sum(rulaj_credit) as suma_credit
	into #RulajeCont
	from rulaje r
	inner join #conturi c on c.cont=r.cont
	where subunitate=@sub and Valuta='' and data between dbo.BOY(@bom_data_lunii) and @data_lunii
	group by r.cont
	
	insert into #RulajeCont
	select 'LUNA', r.cont, sum(rulaj_debit) as suma_debit, sum(rulaj_credit) as suma_credit
	from rulaje r
	inner join #conturi c on c.cont=r.cont
	where subunitate=@sub and Valuta='' and data between @bom_data_lunii and @data_lunii
	group by r.cont

	/*	Calcul date descarcare gestiuni. Calcul coeficient K, adaos pe stoc, adaos de descarcat, cheltuiala, TVA neexigibil.	*/
	select substring(cont,charindex('.',rtrim(cont))+1,20) as gestiune, 
		sum(case when rc.tipSuma='LUNA' and cont like '371%' then Suma_debit else 0 end) as RLD371,
		sum(case when rc.tipSuma='LUNA' and cont like '371%' then Suma_credit else 0 end) as RLC371,
		sum(case when rc.tipSuma='LUNA' and cont like '378%' then Suma_debit else 0 end) as RLD378,
		sum(case when rc.tipSuma='LUNA' and cont like '378%' then Suma_credit else 0 end) as RLC378,
		sum(case when rc.tipSuma='LUNA' and cont like '4428%' then Suma_debit else 0 end) as RLD4428,
		sum(case when rc.tipSuma='LUNA' and cont like '4428%' then Suma_credit else 0 end) as RLC4428,
		sum(case when rc.tipSuma='LUNA' and cont like '707%' then Suma_debit else 0 end) as RLD707,
		sum(case when rc.tipSuma='LUNA' and cont like '707%' then Suma_credit else 0 end) as RLC707,
		sum(case when rc.tipSuma='AN' and cont like '371%' then Suma_debit else 0 end) as TSD371,
		sum(case when rc.tipSuma='AN' and cont like '371%' then Suma_credit else 0 end) as TSC371,
		sum(case when rc.tipSuma='AN' and cont like '378%' then Suma_debit else 0 end) as TSD378,
		sum(case when rc.tipSuma='AN' and cont like '378%' then Suma_credit else 0 end) as TSC378,
		sum(case when rc.tipSuma='AN' and cont like '4428%' then Suma_debit else 0 end) as TSD4428,
		sum(case when rc.tipSuma='AN' and cont like '4428%' then Suma_credit else 0 end) as TSC4428,
		sum(case when rc.tipSuma='AN' and cont like '707%' then Suma_debit else 0 end) as TSD707,
		sum(case when rc.tipSuma='AN' and cont like '707%' then Suma_credit else 0 end) as TSC707,
		convert(decimal(17,6),0) as Coeficient_K, convert(decimal(12,2),0) as SD371, convert(decimal(12,2),0) as SC4428, convert(decimal(12,2),0) as SC378, 
		convert(decimal(12,2),0) as AdaosPeStoc, convert(decimal(12,2),0) as AdaosDesc, convert(decimal(12,2),0) as TVANeexigibil, convert(decimal(12,2),0) as Cheltuiala, 
		convert(varchar(100),'') as explicatii, convert(varchar(9),'') as lm
	into #DescVal
	from #RulajeCont rc
	group by substring(cont,charindex('.',rtrim(cont))+1,20)

	if @optDesc=1 and (@Dafora=1 or @Pragmatic=1)
		update #DescVal set RLC4428=RLD371*@cotaTVA/(@cotaTVA+100), TSC4428=TSD371*@cotaTVA/(@cotaTVA+100)

	if @optDesc=2
		update #DescVal set SD371=TSD371-TSC371, SC4428=TSC4428-TSD4428, SC378=TSC378-TSD378

	/*	Descarcare la vanzari cumulate.	*/
	update #DescVal set 
		Coeficient_K=(case	when @optDesc in (0,2) then convert(decimal(17,6),TSC378/(TSD371-TSC4428)) 
							else (case when @calculKLaVanzariLunare=1 then RLC378/(RLD371-RLC4428) else TSC378/(TSD371-TSC4428) end) end)
	from #DescVal 

	update d set 
		d.AdaosPeStoc=(case when @optDesc=0 then d.Coeficient_K*d.TSC707 when @optDesc=2 then d.Coeficient_K*(SD371-SC4428-RLC707) else 0 end)
	from #DescVal d
	
	update #DescVal set 
		AdaosDesc=(case when @optDesc=0 then AdaosPeStoc-TSD378 when @optDesc=1 then Coeficient_K*(v.Suma_incasata-v.TVA_incasat) when @optDesc=2 then SC378-AdaosPeStoc end)
	from #DescVal d
	left outer join #venituri v on v.gestiune=d.gestiune

	update r set 
		Cheltuiala=v.Suma_incasata-v.TVA_incasat-r.AdaosDesc, explicatii='Desc. gestiune '+rtrim (r.gestiune)+' K='+rtrim (convert(char(10),Coeficient_K))
	from #DescVal r
	left outer join #venituri v on v.gestiune=r.gestiune

	if @DescFaraTVANeex=0
		update r set 
			r.TVANeexigibil=r.TVANeexigibil+v.TVA_incasat
		from #DescVal r
		left outer join #venituri v on v.gestiune=r.gestiune
	
	/*	Completare loc de munca cu locul de munca al gestiunii. */
	update r set r.lm=isnull(nullif(g.detalii.value('(/row/@lm)[1]','varchar(9)'),''),gc.loc_de_munca)
	from #DescVal r
	left outer join gestiuni g on g.cod_gestiune=r.gestiune and g.subunitate =@sub
	left outer join gestcor gc on gc.gestiune=r.gestiune
	
	/*	Apel procedura specifica care permite alterarea tabelei ##DescVal (ex. modificare sume descarcate). */
	if exists (select * from sysobjects where name ='inchidereGestiuniValoriceSP')
		exec inchidereGestiuniValoriceSP @sesiune=@sesiune, @parXML=@parXML

	--select * from #DescVal
	insert into DescVal (Subunitate, Gestiune, TSD371, TSC378, TSC4428, RCumDB378, RCumCR707, Coeficient_K, RLunCR707, Total_incasat, Tva_colectat_11, Tva_colectat_22, SD371, SC4428, SC378)
	select @sub, r.gestiune, r.TSD371, r.TSC378, r.TSC4428, r.TSD378, TSC707, r.Coeficient_K, RLC707, v.Suma_incasata, 0, v.TVA_incasat, SD371, SC4428, SC378
	from #DescVal r
	left outer join #venituri v on v.gestiune=r.gestiune

	CREATE TABLE #ncon_dgv
	(
		tip varchar(2),
		numar varchar(13) ,
		data datetime,
		cont_debitor varchar(40) ,
		cont_creditor varchar(40),
		suma decimal(17,2),
		explicatii varchar(50),
		lm varchar(9),
		detalii xml
	)

	insert into #ncon_dgv (tip, numar, data ,cont_debitor, cont_creditor, suma, explicatii, lm, detalii)
	select
		'IC', @numar_doc, @data_lunii, rtrim(@contCheltVanz)+'.'+rtrim(d.gestiune), '371'+'.'+rtrim(d.gestiune), CONVERT(DECIMAL(17,2),Cheltuiala), explicatii, lm, 
		(select 'Cheltuiala ('+convert(varchar(20),convert(decimal(12,2),Cheltuiala))+')='
			+'Suma Incasata ('+convert(varchar(20),convert(decimal(12,2),Suma_incasata))+')-TVA Incasat ('+convert(varchar(20),convert(decimal(12,2),TVA_incasat))+')'+
			+'-Adaos descarcat ('+convert(varchar(20),convert(decimal(12,2),AdaosDesc))+')' as expl_dgval for xml raw)
	from #DescVal d
	left outer join #venituri v on v.gestiune=d.gestiune
	union all
	select
		'IC', @numar_doc, @data_lunii, rtrim(@contAdaos)+'.'+rtrim(gestiune), '371'+'.'+rtrim(gestiune), CONVERT(DECIMAL(17,2),AdaosDesc), explicatii, lm, 
		(select 'Coeficient_K ('+convert(varchar(20),convert(decimal(17,6),Coeficient_K))+')=TSC378 ('+convert(varchar(20),convert(decimal(12,2),TSC378))
			+')/(TSD371 ('+convert(varchar(20),convert(decimal(12,2),TSD371))+')-TSC4428 ('+convert(varchar(20),convert(decimal(12,2),TSC4428))+'))' 
		+' Adaos de descarcat ('+convert(varchar(20),convert(decimal(12,2),AdaosDesc))+')=Coeficient_K ('+convert(varchar(20),convert(decimal(17,6),Coeficient_K))
			+')*RCumCR707 ('+convert(varchar(20),convert(decimal(12,2),TSC707))+')-RCumDB378 ('+convert(varchar(20),convert(decimal(12,2),TSD378))+')'
		as expl_dgval for xml raw)
	from #DescVal
	union all
	select
		'IC', @numar_doc, @data_lunii, isnull(c.cont,rtrim(@contTvaNeexigil)), '371'+'.'+rtrim(d.gestiune), CONVERT(DECIMAL(17,2),TVANeexigibil), explicatii, lm, 
		(select 'TVA nexigibil=TVA incasat('+convert(varchar(20),convert(decimal(12,2),TVA_incasat))+')' as expl_dgval for xml raw)
	from #DescVal d
	left outer join conturi c on c.cont=rtrim(@contTvaNeexigil)+'.'+rtrim(gestiune) and c.subunitate=@sub
	left outer join #venituri v on v.gestiune=d.gestiune

	/*	Apel procedura specifica care permite alterarea tabelei #ncon_dgv (ex. modificare conturi). */
	if exists (select * from sysobjects where name ='inchidereGestiuniValoriceSP1')
		exec inchidereGestiuniValoriceSP1 @sesiune=@sesiune, @parXML=@parXML

	insert into PozNCon 
		(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal, detalii)
	select @sub, tip, numar, data, cont_debitor, cont_creditor, suma, '', 0, 0, explicatii, 
		@utilizator, convert(datetime, convert(char(10), getdate(), 104), 104), RTRIM(replace(convert(char(8), getdate(), 108), ':', '')), 
		@nr_pozitie+row_number() over (order by cont_creditor, cont_debitor), lm, '', '', 'DV', detalii
	from #ncon_dgv where abs(suma)>=0.01
	
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data_lunii

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
