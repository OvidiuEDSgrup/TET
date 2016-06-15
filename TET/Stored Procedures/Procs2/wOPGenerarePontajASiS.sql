
CREATE procedure wOPGenerarePontajASiS @sesiune varchar(50), @parXML XML
as
begin try
	set transaction isolation level read uncommitted
	declare @tipgenerare int, @datainceput datetime, @datasfarsit datetime, @marca varchar(6), @lm varchar(9), 
		@PontajZilnic int, @RegimVariabil int, @OreLuna float, @OreLunaMediu float, @mesaj varchar(500), @parXML1 xml, @docPontaj xml

	set @tipgenerare = @parXML.value('(/*/@tipgenerare)[1]', 'int')
	set @datainceput = @parXML.value('(/*/@datainceput)[1]', 'datetime')
	set @datasfarsit = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')
	set @marca = isnull(@parXML.value('(/*/@marca)[1]', 'varchar(6)'),'')
	set @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(9)'),'')
	set @PontajZilnic=dbo.iauParL('PS','PONTZILN')
	set @RegimVariabil=dbo.iauParL('PS','REGIMLV')
	set @OreLuna=dbo.iauParLN(dbo.eom(@datasfarsit),'PS','ORE_LUNA')
	set @OreLunaMediu=dbo.iauParLN(dbo.eom(@datasfarsit),'PS','NRMEDOL')

--	set @PontajZilnic=1
	set @parXML1=(select 'OP' tip for xml raw)
	
	if object_id('tempdb..#pontaj') is not null drop table #pontaj

	if @tipgenerare=0
		delete from Pontaj where data between @datainceput and @datasfarsit
			and (@marca='' or marca=@marca)
			and (@lm='' or Loc_de_munca=@lm)

	Create table #pontaj 
		(tip char(1), idPontajElectronic int, idProgramDeLucru int, marca varchar(6), data datetime, loc_de_munca varchar(9), 
		tip_programare varchar(50), data_inceput_prg datetime, ora_start_prg varchar(10), data_sfarsit_prg datetime, ora_stop_prg varchar(10), ore_program int, 
		data_ora_intrare datetime, ora_intrare varchar(10), data_ora_iesire datetime, ora_iesire varchar(10), tip_ore_pontaj varchar(50), ore_pontaj int)

	insert into #pontaj 
		(tip, idPontajElectronic, idProgramDeLucru, marca, data, loc_de_munca, 
		tip_programare, data_inceput_prg, ora_start_prg, data_sfarsit_prg, ora_stop_prg, ore_program, 
		data_ora_intrare, ora_intrare, data_ora_iesire, ora_iesire, tip_ore_pontaj, ore_pontaj)
	exec wPontajRezultat '', @parXML
	
--	scriu datele in pontaj
	insert into pontaj (Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, 
		Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, 
		Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, 
		Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program, Ore_sistematic_peste_program, 
		Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, 
		Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10) 
	select convert(char(10),data,101) data, rtrim(b.marca) marca, row_number() over (partition by b.marca order by data) nrcrt,
		isnull(b.loc_de_munca,p.Loc_de_munca) as loc_de_munca, 1, p.Tip_salarizare, rl.RL, 
		round(p.Salar_de_incadrare/(case when @RegimVariabil=1 and p.Salar_lunar_de_baza<>0 then 
		p.Salar_lunar_de_baza*(case when p.Tip_salarizare in ('1','2') then @OreLuna else @OreLunaMediu end) 
		else (case when p.Tip_salarizare in ('1','2') then @OreLuna*(case when @RegimVariabil=0 then rl.RL/8 else 1 end) else @OreLunaMediu end) end),4) as salar_orar, 
		isnull(convert(int,Ore_regie),0) + isnull(convert(int,Ore_acord),0) as ore_lucrate, 
		isnull(convert(int,Ore_regie),0) as ore_regie, isnull(convert(int,Ore_acord),0) as ore_acord, 
		isnull(convert(int,Ore_suplimentare_1),0) as ore_suplimentare_1, isnull(convert(int,Ore_suplimentare_2),0) as ore_suplimentare_2, 
		isnull(convert(int,Ore_suplimentare_3),0) as ore_suplimentare_3, isnull(convert(int,Ore_suplimentare_4),0) as ore_suplimentare_4, 0 as ore_spor_100, 
		isnull(convert(int,Ore_de_noapte),0) as ore_de_noapte, isnull(convert(int,Ore_intrerupere_tehnologica_1),0) as Ore_intrerupere_tehnologica, 
		isnull(convert(int,Ore_concediu_de_odihna),0) as Ore_concediu_de_odihna, isnull(convert(int,Ore_concediu_medical),0) as Ore_concediu_medical, 
		isnull(convert(int,Ore_invoiri),0) as ore_invoiri, isnull(convert(int,Ore_nemotivate),0) as ore_nemotivare, 
		isnull(convert(int,Ore_obligatii_cetatenesti),0) as Ore_obligatii_cetatenesti, isnull(convert(int,Ore_concediu_fara_salar),0) as Ore_concediu_fara_salar,
		0 as ore_donare_sange, 0 as Salar_categoria_lucrarii, 0 as Coeficient_acord, 0 as Realizat, 
		0 as Coeficient_de_timp, 0 as Ore_realizate_acord, p.Spor_sistematic_peste_program as Sistematic_peste_program, 0 as Ore_sistematic_peste_program, 
		p.Spor_specific as Spor_specific, p.Spor_conditii_1 as Spor_conditii_1, p.Spor_conditii_2 as Spor_conditii_2, 
		p.Spor_conditii_3 as Spor_conditii_3, p.Spor_conditii_4 as Spor_conditii_4, p.Spor_conditii_5 as Spor_conditii_5, p.Spor_conditii_6 as Spor_conditii_6, 
		0 as Ore__cond_1, 0 as Ore__cond_2, 0 as Ore__cond_3, 0 as Ore__cond_4, 0 as Ore__cond_5, 0 as Nr_tichete, 
		(case when p.Grupa_de_munca in ('C','P') then 'N' else p.Grupa_de_munca end) as Grupa_de_munca, 
		isnull(convert(int,b.Ore),0) as Ore, isnull(p.Spor_cond_7,0), isnull(p.Spor_cond_8,0), 		
		isnull(convert(int,Ore_detasare),0) as Spor_cond_9, isnull(convert(int,b.Spor_cond_10),0) as Spor_cond_10
	from 
		(select (case when @PontajZilnic=1 then data else dbo.EOM(data) end) as data, marca, loc_de_munca, tip_ore_pontaj, sum(ore_pontaj) as ore_pontaj 
			from #pontaj group by (case when @PontajZilnic=1 then data else dbo.EOM(data) end), marca, loc_de_munca, tip_ore_pontaj) a
				pivot (sum(ore_pontaj) 
					for tip_ore_pontaj in (Ore_regie,Ore_acord,Ore_suplimentare_1,Ore_suplimentare_2,Ore_suplimentare_3,Ore_suplimentare_4,
					Ore_de_noapte,Ore_intrerupere_tehnologica_1,Ore,Ore_concediu_de_odihna,Ore_concediu_medical,
					Ore_obligatii_cetatenesti,Ore_invoiri,Ore_nemotivate,Ore_concediu_fara_salar,Spor_cond_10,Ore_detasare)) b
		left outer join personal p on p.Marca=b.marca
		left outer join dbo.fDate_pontaj_automat (dbo.BOM(@datainceput), dbo.EOM(@datasfarsit), dbo.EOM(@datasfarsit), 'RL', '', 0, 0) rl on b.Marca=rl.Marca
	
	if exists (select 1	from sysobjects where name = 'wOPGenerarePontajASiSSP')
		exec wOPGenerarePontajASiSSP @sesiune = @sesiune, @parXML = @parXML

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPGenerarePontajASiS)'

	raiserror (@mesaj, 11, 1)
end catch
