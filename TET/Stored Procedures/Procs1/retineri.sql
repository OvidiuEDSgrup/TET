--***
/**	procedura lista retineri	*/
Create 
procedure [dbo].[retineri] @MarcaJos char(6), @MarcaSus char(6), @DataJos datetime, @DataSus datetime,
@LmJos char(9), @LmSus char(9), @BenefJos char(13), @BenefSus char(13), @nRetla int, @cTipla char(1), @unSubtipret int, @cSubtipret char(1), @unTipret int, @cTipret char(1), @nGrupare int, @nOrdonare int
as
Begin
	declare @detret int, @tLmJos int, @lMarcaJos int, @lBenefJos int 
	set @tLmJos=(case when isnull(@LmJos,'')<>'' then 1 else 0 end)
	set @lMarcaJos=(case when isnull(@MarcaJos,'')<>'' then 1 else 0 end)
	set @lBenefJos=(case when isnull(@BenefJos,'')<>'' then 1 else 0 end)
	Set @detret = isnull((select val_logica from par where tip_parametru='PS' and parametru='SUBTIPRET'),0)

	declare @utilizator varchar(20)

SET @utilizator = dbo.fIaUtilizator(null)
	IF @utilizator IS NULL
		RETURN -1

	select a.Data, a.marca, a.cod_beneficiar, a.Numar_document, a.Data_document, a.Valoare_totala_pe_doc, 
	a.Valoare_retinuta_pe_doc, a.Retinere_progr_la_avans, a.Retinere_progr_la_lichidare, a.procent_progr_la_lichidare, 
	a.Retinut_la_avans, a.Retinut_la_lichidare, isnull(r.Retinere_progr_la_avans,0) as Numar_chitanta, isnull(r.Retinut_la_lichidare,0) as Valoare_chitanta, 
	b.nume, b.salar_de_incadrare, convert (int,b.loc_ramas_vacant) as loc_ramas_vacant, 
	isnull(c.loc_de_munca,b.loc_de_munca) as loc_de_munca, isnull(c.Venit_Net,0) as venit_net, 
	a.Retinere_progr_la_lichidare+round((case when substring(d.Cod_fiscal,10,1)='2' then isnull(c.Venit_Net,0) 
	else b.salar_de_incadrare end)*a.procent_progr_la_lichidare/100,0) as retinere_cu_procent,
	(case when a.Valoare_totala_pe_doc=a.Valoare_retinuta_pe_doc then 0 else 
	a.Retinere_progr_la_avans+a.retinere_progr_la_lichidare+round((case when substring(d.Cod_fiscal,10,1)='2' then isnull(c.Venit_Net,0) 
	else b.salar_de_incadrare end)*a.procent_progr_la_lichidare/100,0)-a.retinut_la_avans-a.Retinut_la_lichidare end) as diferenta,
	(case when a.Valoare_totala_pe_doc>0 then a.Valoare_totala_pe_doc-a.Valoare_retinuta_pe_doc else 0 end) as valoare_ramasa,
	d.tip_retinere,d.denumire_beneficiar,d.Obiect_retinere,d.Cod_fiscal,d.banca,d.cont_banca,
	e.Val_inf, e.Data_inf, f.subtip, f.denumire as denumire_subtip, f.tip_retinere as tip_retinere_din_tipret, f.obiect_subtip_retinere,
	h.denumire as denumire_lm, (case when g.afisat<>0 then 1 else 0 end) as afisat, 
	(case when i.se_afiseaza<>0 then 1 else 0 end) as se_afiseaza,
	(case when @ngrupare=1 then a.cod_beneficiar else '' end) as Ordonare_codb1,
	(case when @ngrupare=2 then a.cod_beneficiar else '' end) as Ordonare_codb2, 
	(case when @ngrupare=2 then isnull(c.loc_de_munca,b.loc_de_munca) else '' end) as Ordonare_lm,
	(case when @ngrupare=1 then (case when @detret=1 then f.tip_retinere+f.subtip else d.Tip_retinere end) else '' end) as Ordonare_tip_retinere
	from resal a  
	left outer join personal b on a.marca=b.marca
	left outer join net c on a.data=c.data and a.marca=c.marca 
	left outer join benret d on a.cod_beneficiar=d.cod_beneficiar  
	left outer join extinfop e on a.marca=e.marca and e.cod_inf='CONT2' and e.val_inf<>''
	left outer join tipret f on d.tip_retinere=f.subtip 
	left outer join lm h on c.loc_de_munca=h.cod 
	left outer join 
	(select x.loc_de_munca, sum(y.Retinere_progr_la_avans+y.retinere_progr_la_lichidare-y.retinut_la_avans-y.Retinut_la_lichidare) as afisat from resal y left outer join net x on y.marca=x.marca and y.data=x.data group by x.loc_de_munca) g on g.loc_de_munca=isnull(c.loc_de_munca,b.loc_de_munca)
	left outer join (select cod_beneficiar, sum(Retinere_progr_la_avans+retinere_progr_la_lichidare-retinut_la_avans-Retinut_la_lichidare) as se_afiseaza from resal group by cod_beneficiar) i on i.cod_beneficiar=a.cod_beneficiar 
	left outer join resal r on r.data=DateAdd(year,1000,a.Data) and r.Marca=a.Marca and r.Cod_beneficiar=a.Cod_beneficiar and r.Numar_document=a.Numar_document
	where a.data between @DataJos and @DataSus and (@lMarcaJos=0 or a.marca=@MarcaJos) 
	and (@tLmJos=0 or (isnull(c.loc_de_munca,b.loc_de_munca) like rtrim(@LmJos)+'%'))
	and (@lBenefJos=0 or a.cod_beneficiar=@BenefJos) 
	and (@nRetla=0 or @cTipla='A' and a.retinut_la_avans<>0 or @cTipla='L' and a.retinut_la_lichidare<>0) 
	and (not(@detret=1 and @unSubtipret=1) or d.tip_retinere=isnull(@cSubtipret,'')) 
	and (not(not(@detret=1) and @unTipret=1) or d.tip_retinere=@cTipret) 
	and (not(@detret=1 and @unTipret=1) or f.tip_retinere=@cTipret)
	and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(c.loc_de_munca,b.loc_de_munca)))
	order by Ordonare_lm, Ordonare_tip_retinere, Ordonare_codb1, (case when @nordonare=2 then b.nume else a.marca end), Ordonare_codb2, a.numar_document, a.data
End
