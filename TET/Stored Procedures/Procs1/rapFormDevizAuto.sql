--***
create procedure rapFormDevizAuto @sesiune varchar(50), @nrdeviz varchar(20), @piese bit, @manopera bit
as
begin try
	declare
		@utilizator varchar(20), @unitate varchar(150), @cif varchar(50),
		@ordreg varchar(50), @sediu varchar(150), @judet varchar(100)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	set @unitate = (select rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'NUME')
	set @cif = (select rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'CODFISC')
	set @ordreg = (select rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'ORDREG')
	set @sediu = (select rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'SEDIU')
	set @judet = (select rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'JUDET')

	/** Aducem detaliile pieselor: in raport se va apela procedura cu parametrii @piese=1 si @manopera=0
	*	Am facut un dataset separat pentru piese (similar Manopera), respectiv un tabel cu piesele.
	*/
	if @piese = 1
	begin
		select
			rtrim(pdv.Cod) as codPiesa,
			rtrim(n.Denumire) as denPiesa,
			convert(decimal(15,2), pdv.Cantitate) as cantPiesa,
			convert(decimal(17,3), pdv.Pret_vanzare) as pretPiesa,
			pdv.Discount as discountPiesa,
			round(pdv.cantitate * pdv.pret_vanzare * (1 - pdv.discount/100) * pdv.cota_TVA/100.00, 2) as tvaPiesa,
			round(pdv.cantitate * pdv.pret_vanzare, 2) as valPiesa
		from pozdevauto pdv
		inner join nomencl n on n.Cod = pdv.Cod
		where pdv.Tip_resursa = 'P' and pdv.Cod_deviz = @nrdeviz
		order by pdv.Cod
	return
	end

	/** Aducem detaliile manoperei: in raport se va apela procedura cu parametrii @piese=0 si @manopera=1 */
	if @manopera = 1
	begin
		select
			rtrim(pdm.Cod) as codOperatie,
			rtrim(c.Denumire) as denOperatie,
			pdm.Timp_normat as timpManopera,
			convert(decimal(17,3), pdm.Tarif_orar) as tarifManopera,
			round(pdm.cantitate * pdm.pret_vanzare, 2) as valOperatie,
			round(pdm.cantitate * pdm.pret_vanzare * (1 - pdm.discount/100) * pdm.cota_TVA/100.00, 2) as tvaOperatie,
			round(pdm.cantitate * pdm.pret_vanzare * (1 - pdm.discount/100) * (1.00 + pdm.cota_TVA/100.00), 2) as totalOperatie
		from pozdevauto pdm
		inner join catop c on c.Cod = pdm.Cod
		where pdm.Tip_resursa = 'M' and pdm.Cod_deviz = @nrdeviz
		order by pdm.Cod
	return
	end

	/** Pentru select-ul principal, se va apela procedura in raport cu parametrii @piese=0 si @manopera=0,
	*	ca sa nu mai aducem inca o data aceleasi date. 
	*/
	select
		/** Antet */
		@unitate as UNITATE, @cif as CIF, @ordreg as ORDREG, @sediu as LOCALITATE, @judet as JUDET,
		rtrim(dv.Cod_deviz) as NRDEVIZ,
		convert(varchar(10), dv.Data_lansarii, 103) as DATA,
		convert(varchar(10), dv.Data_inchiderii, 103) as DATAI,
		rtrim(t.Denumire) as DENTERT,
		rtrim(t.Adresa) as ADRTERT,
		rtrim(t.Localitate) as LOCTERT,
		rtrim(t.Judet) as JUDTERT,
		rtrim(a.Marca) + ' ' + rtrim(a.Model) + ' ' + rtrim(a.Cilindree) + ' ' + rtrim(a.Putere_motor) as MASINA,
		rtrim(a.Nr_circulatie) as NRINMATRICULARE,
		rtrim(a.Serie_de_motor) as SERIEMOTOR,
		rtrim(a.Serie_de_sasiu) as SERIESASIU,
		rtrim(convert(decimal(15,0), dv.KM_bord)) as KMBORD,
		rtrim(a.Tip_auto) as TIPMOTOR,

		/** Total piese */
		round((select isnull(sum(p.cantitate * p.pret_vanzare), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'P'), 2) as valPiese,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * p.discount/100), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'P'), 2) as discountPiese,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * p.cota_TVA/100.00), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'P'), 2) as tvaPiese,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * (1.00 + p.cota_TVA/100.00)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'P'), 2) as totalPiese,

		/** Total manopera */
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * (1.00 + p.cota_TVA/100.00)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'M'), 2) as totalManopera,
		round((select isnull(sum(p.cantitate * p.timp_normat), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'M'), 2) as totalTimpManopera,

		/** Total refacturare */
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * (1.00 + p.cota_TVA/100.00)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa = 'R'), 2) as totalRefacturat,

		/** Refacturare manopera */
		round((select isnull(sum(p.cantitate * p.pret_vanzare), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('M', 'R')), 2) as valManoperaRefacturat,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * p.discount/100), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('M', 'R')), 2) as discountManoperaRefacturat,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * p.cota_TVA/100.00), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('M', 'R')), 2) as tvaManoperaRefacturat,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * (1.00 + p.cota_TVA/100.00)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('M', 'R')), 2) as totalManoperaRefacturat,

		/** Total general */
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('P', 'M', 'R')), 2) as valTotal,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * p.cota_TVA/100.00), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('P', 'M', 'R')), 2) as tvaTotal,
		round((select isnull(sum(p.cantitate * p.pret_vanzare * (1 - p.discount/100) * (1.00 + p.cota_TVA/100.00)), 0)
			from pozdevauto p where p.cod_deviz = dv.cod_deviz and p.tip_resursa in ('P', 'M', 'R')), 2) as total
	from devauto dv
	left join terti t on t.Tert = dv.Beneficiar
	left join auto a on a.Cod = dv.Autovehicul
	where dv.Cod_deviz = @nrdeviz
	
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch

/*
exec rapFormDevizAuto '', '21162', 0,1
exec rapFormDevizAuto '', '21162', 1,0
exec rapFormDevizAuto '', '21162', 0,0
*/
