--***
/**	functie evid. fortei de munca	*/
Create
function [dbo].[evolutie_forta_de_munca]
	(@Datajos datetime, @Datasus datetime, @Marca_jos char(6), @Marca_sus char(6), @locm_jos char(9), @locm_sus char(9), 
	@ltip_salarizare bit, @ctip_sal_jos char(1), @ctip_sal_sus char(1), @lfunctie bit, @cfunctie char(6), @ltip_stat bit, @ctip_stat char(200)) 
returns @evolutie_forta_de_munca table
	(Data datetime, Tip_pers char(30), Cod_functie char(6), Denumire_functie char(30), Numar_salariati int, Cheltuieli_1 float)
as
begin
	declare @evolutie_fm table (Data datetime, Marca char(6), Tip_personal char(30), Cod_functie char(6), Denumire_functie char(30), Numar_salariati int, Cheltuieli_1 float)

	insert into @evolutie_fm
	select a.Data, a.Marca, 
	isnull((select top 1 val_inf from extinfop e where e.marca=a.marca 
	and e.Cod_inf='TIPPERS' and e.data_inf<=a.Data order by e.Data_inf desc),'NECOMPLETAT') as Tippers,
	i.cod_functie, f.denumire, count(i.cod_functie) as Numar_salariati,
	sum(round(a.Venit_total-a.ind_c_medical_cas-a.CMFAMBP+a.CAS_unitate+a.Somaj_5+a.Fond_garantare+
	a.Asig_sanatate_pl_unitate+a.Fond_de_risc_1+a.Camera_de_Munca_1+a.CCI+CASS_AMBP,0))+round(max(Cotiz_hand)* count(i.Cod_functie)/(select count(1) from net n where n.data=a.data and n.Venit_total<>0),0) as Cheltuieli_1
	from dbo.fluturas_centralizat(@Datajos, @Datasus ,@Marca_jos, @Marca_sus, @locm_jos, @locm_sus, 0, '', @ltip_salarizare, @ctip_sal_jos, @ctip_sal_sus, 0, '', @lfunctie, @cfunctie, 0, '', 0, '', 0, '', @ltip_stat, @ctip_stat, 1, 'T', 0, '', 0, '', '', 0, 0, 'MARCA', Null) a
		inner join istpers i on a.marca = i.marca and a.data = i.data
		inner join functii f on i.cod_functie = f.cod_functie
	where a.ingr_copil=0
	group by i.cod_functie, a.data, f.denumire, a.Marca
	order by a.data

	insert @evolutie_forta_de_munca
	select Data, Tip_personal, Cod_functie, Denumire_functie, sum(Numar_salariati), sum(Cheltuieli_1)
	from @evolutie_fm
	group by Data, Tip_personal, Cod_functie, Denumire_functie
	order by Data

	return
end

/*
	select * from dbo.evolutie_forta_de_munca ('05/01/2008', '07/31/2008', '', 'ZZZ','', 'ZZZ', 0, '', '', 1, 'DE', 0, '')
*/
