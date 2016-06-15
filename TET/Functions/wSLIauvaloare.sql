--***
Create function wSLIauvaloare (@data datetime, @marca varchar(6), @loc_de_munca varchar(9), @subtip varchar(2), @numar_curent int)
returns float
as
begin
	declare @COEV_macheta int, @data1 datetime, @data2 datetime, @ore float, @tore float, @val float, @valret float, @oresupl float,
	@ore1 float, @tore1 float, @val1 float, @ore2 float, @tore2 float, @val2 float,	@ore3 float, @tore3 float, @val3 float, @ore4 float, @tore4 float, @val4 float,
	@ore100 float, @tore100 float, @val100 float, @oren float, @toren float, @valn float, @orer float, @torer float, @valr float, @orea float, @torea float, @vala float,
	@minregie1 int, @minregie2 int, @ORegieFaraOS2 int, @vallucrat float, @valnelucrat float, @oreco float, @toreco float,@valco float, @orecm float, @torecm float,@valcm float

	set @COEV_macheta=dbo.iauParL('PS','COEVMCO')
	set @data1=dbo.bom(@data) 
	set @data2=dbo.eom(@data)
	set @minregie1=dbo.iauParL('PS','OSNRN')
	set @minregie2=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	select @valret=0, @vallucrat=0, @valnelucrat=0

	select @orer=(ore_regie-(case when @minregie1=1 and 1=0 then (ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4) else 0 end)-
		(case when @minregie2=1 and 1=0 then Ore_spor_100 else 0 end)), @orea=ore_acord,
		@oresupl=(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4),
		@ore1=Ore_suplimentare_1,@ore2=Ore_suplimentare_2,@ore3=Ore_suplimentare_3,@ore4=Ore_suplimentare_4,@ore100=Ore_spor_100,@oren=ore_de_noapte 
	from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent
	select @torer=ore_lucrate__regie,@torea=ore_lucrate_acord,
		@valr=realizat__regie+Salar_categoria_lucrarii,@vala=realizat_acord,@tore1=Ore_suplimentare_1,@tore2=Ore_suplimentare_2,@tore3=Ore_suplimentare_3, @tore4=Ore_suplimentare_4,@tore100=Ore_spor_100,
		@val1=indemnizatie_ore_supl_1,@val2=indemnizatie_ore_supl_2,@val3=indemnizatie_ore_supl_3,@val4=indemnizatie_ore_supl_4, @val100=indemnizatie_ore_spor_100,@toren=ore_de_noapte,@valn=ind_ore_de_noapte 
	from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca
	
	set @vallucrat=(case when isnull(@torer,0)=0 then 0 else round((isnull(@valr,0)*isnull(@orer,0))/@torer,2) end)+
		(case when isnull(@torea,0)=0 then 0 else round((isnull(@vala,0)*isnull(@orea,0))/@torea,2) end)+
		(case when isnull(@tore1,0)=0 then 0 else round((isnull(@val1,0)*isnull(@ore1,0))/@tore1,2) end)+
		(case when isnull(@tore2,0)=0 then 0 else round((isnull(@val2,0)*isnull(@ore2,0))/@tore2,2) end)+
		(case when isnull(@tore3,0)=0 then 0 else round((isnull(@val3,0)*isnull(@ore3,0))/@tore3,2) end)+
		(case when isnull(@tore4,0)=0 then 0 else round((isnull(@val4,0)*isnull(@ore4,0))/@tore4,2) end)+
		(case when isnull(@tore100,0)=0 then 0 else round((isnull(@val100,0)*isnull(@ore100,0))/@tore100,2) end)+
		(case when isnull(@toren,0)=0 then 0 else round((isnull(@valn,0)*isnull(@oren,0))/@toren,2) end)

	select @ore1=Ore_intrerupere_tehnologica, @ore2=Ore, @ore3=Ore_obligatii_cetatenesti, @oreco=Ore_concediu_de_odihna, @orecm=Ore_concediu_medical
	from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent
	select @tore1=sum(Ore_intrerupere_tehnologica), @tore2=sum(Ore), @tore3=sum(Ore_obligatii_cetatenesti), @toreco=sum(Ore_concediu_de_odihna), @torecm=sum(Ore_concediu_medical)
	from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca
	select @val1=ind_intrerupere_tehnologica,@val2=ind_invoiri,@val3=ind_obligatii_cetatenesti, @valco=Ind_concediu_de_odihna, @valcm=Ind_c_medical_unitate+Ind_c_medical_cas+spor_cond_9 
	from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca
	set @valnelucrat=(case when isnull(@tore1,0)=0 then 0 else round((isnull(@val1,0)*isnull(@ore1,0))/@tore1,2) end)+
	(case when isnull(@tore2,0)=0 then 0 else round((isnull(@val2,0)*isnull(@ore2,0))/@tore2,2) end)+
	(case when @subtip='P1' and @COEV_macheta=1 or isnull(@tore3,0)=0 then 0 else round((isnull(@val3,0)*isnull(@ore3,0))/@tore3,2) end)+
	(case when @subtip='P1' or isnull(@toreco,0)=0 then 0 else round((isnull(@valco,0)*isnull(@oreco,0))/@toreco,2) end)+
	(case when @subtip='P1' or isnull(@torecm,0)=0 then 0 else round((isnull(@valcm,0)*isnull(@orecm,0))/@torecm,2) end)

	set @valret=@vallucrat+@valnelucrat
	return @valret
end
