
create procedure pDifCursStornareAvans @sesiune varchar(50)=null, @parXML xml=null
as 
/*
Apelata din procedurile wScriuDoc si corectiiDocument
Procedura va primi un set de pozitii documente si va completa in campul detalii diferenta de curs si contul de diferenta curs.
Exemplu de apel:
	exec pDifCursStornareAvans
*/
begin try
	SET NOCOUNT ON
	declare @cSub varchar(20)
	select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'

	declare @ignor4428Avansuri int, @ConturiDocFaraFact varchar(200)
	select @ignor4428Avansuri=isnull((case when parametru='NEEXAV' then val_logica else @ignor4428Avansuri end),0),
		@ConturiDocFaraFact=isnull((case when parametru='NEEXDOCFF' then rtrim(val_alfanumerica) else @ConturiDocFaraFact end),'')
	from par where Tip_parametru='GE' and Parametru in ('NEEXAV','NEEXDOCFF')

	update d set  
		d.val_valuta_storno=abs(round(convert(decimal(17,5),(case when d.tip in ('AP','AC','AS') 
			then round(convert(decimal(17,5),d.pret_valuta*(1-d.discount/100))+(case when d.curs>0 and d.cantitate<>0 and @ignor4428Avansuri=0 then d.tva_deductibil/d.curs/d.cantitate else 0 end),5) 
			else d.pret_valuta*(1+d.discount/100)*(case when (d.tip<>'RM' or d.numar_dvi='') and @ignor4428Avansuri=0 then 1+d.cota_tva/100.00 else 1 end) end)*d.cantitate),2))
	from #documente d
		left outer join conturi c on c.subunitate=@cSub and c.cont=d.cont_de_stoc
	where d.valuta!='' and d.cantitate<0 and d.tip_miscare='V' and charindex(left(d.cont_de_stoc,3),@ConturiDocFaraFact)=0
		and (d.tip in ('RM','RS') and c.Sold_credit=1 or d.tip in ('AP','AS') and c.Sold_credit=2)

	update #documente set  
		dif_curs_av=convert(decimal(11,2),(#documente.val_valuta_storno*#documente.curs-#documente.val_valuta_storno*f.curs))
	from facturi f 
	where f.Subunitate=@cSub and #documente.tert=f.Tert and #documente.cod_intrare=f.Factura and (case when #documente.tip in ('RM','RS') then 0x54 else 0x46 end)=f.Tip
		and #documente.valuta!='' and val_valuta_storno<>0

	if exists (select 1 from #documente where dif_curs_av<>0)
	begin
		declare @ctCheltDifCF varchar(40),@CtVenDifcF varchar(40),@CtCheltDifcB varchar(40),@CtVenDifcB varchar(40)
		select @CtCheltDifcF=isnull((case when parametru='DIFCH' then rtrim(val_alfanumerica) else @CtCheltDifcF end),'')
				,@CtVenDifcF=isnull((case when parametru='DIFVE' then rtrim(val_alfanumerica) else @CtVenDifcF end),'')
				,@CtCheltDifcB=isnull((case when parametru='DIFCHB' then rtrim(val_alfanumerica) else @CtCheltDifcB end),'')
				,@CtVenDifcB=isnull((case when parametru='DIFVEB' then rtrim(val_alfanumerica) else @CtVenDifcB end),'')
		from par where tip_parametru='GE' and parametru in ('DIFCH','DIFVE','DIFCHB','DIFVEB')

		update #documente set  
			cont_dif_av=(case when #documente.tip in ('AP','AS') and #documente.dif_curs_av>=0.01 then @CtCheltDifcB
							when #documente.tip in ('AP','AS') and #documente.dif_curs_av<=0.01 then @CtVenDifcB
							when #documente.tip in ('RM','RS') and #documente.dif_curs_av>=0.01 then @CtVenDifcF
							when #documente.tip in ('RM','RS') and #documente.dif_curs_av<=0.01 then @CtCheltDifcF
						end)
		from facturi f 
		where f.Subunitate=@cSub and #documente.tert=f.Tert and #documente.cod_intrare=f.Factura and (case when #documente.tip in ('RM','RS') then 0x54 else 0x46 end)=f.Tip
			and #documente.valuta!=''  

		update #documente set detalii='<row />'
		where detalii is null and dif_curs_av<>0

		update d set detalii.modify('replace value of (/row/@_difcurs)[1] with sql:column("d.Dif_curs_av")') 
		from #documente d
		where d.detalii.value('(/row/@_difcursav)[1]','float') is not null and Dif_curs_av<>0
		update d set detalii.modify('insert attribute _difcursav {sql:column("d.Dif_curs_av")} into (/row)[1]') 
		from #documente d
		where d.detalii.value('(/row/@_difcursav)[1]','float') is null and Dif_curs_av<>0
	
		update d set detalii.modify('replace value of (/row/@_contdifav)[1] with sql:column("d.cont_dif_av")') 
		from #documente d
		where d.detalii.value('(/row/@_contdifav)[1]','varchar(40)') is not null and Dif_curs_av<>0
		update d set detalii.modify('insert attribute _contdifav {sql:column("d.cont_dif_av")} into (/row)[1]') 
		from #documente d
		where d.detalii.value('(/row/@_contdifav)[1]','varchar(40)') is null and Dif_curs_av<>0
	end
end try

begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
