--***
/**	procedura scriu pontaj	*/
Create procedure scriuPontaj 
	(@data datetime, @marca char(6), @numar_curent int, @loc_de_munca char(9), @loc_munca_pentru_stat_de_plata int, @tip_salarizare char(1), @regim_de_lucru float, @salar_orar float, 
	@ore_regie int, @ore_acord int, @ore_suplimentare_1 int, @ore_suplimentare_2 int, @ore_suplimentare_3 int, @ore_suplimentare_4 int, @ore_spor_100 int, 
	@ore_de_noapte int, @ore_intrerupere_tehnologica int, @ore_concediu_de_odihna int, @ore_concediu_medical int, @ore_invoiri int, @ore_nemotivate int, 
	@ore_obligatii_cetatenesti int, @ore_concediu_fara_salar int, @ore_donare_sange int, @salar_categoria_lucrarii float, 
	@coeficient_acord float, @realizat float, @coeficient_de_timp float, @ore_realizate_acord float, 
	@sistematic_peste_program float, @ore_sistematic_peste_program int, @spor_specific float, 
	@spor_conditii_1 float, @spor_conditii_2 float, @spor_conditii_3 float, @spor_conditii_4 float, @spor_conditii_5 float, @spor_conditii_6 float, 
	@ore__cond_1 int, @ore__cond_2 int, @ore__cond_3 int, @ore__cond_4 int, @ore__cond_5 int, @ore__cond_6 int, 
	@grupa_de_munca char(1), @ore int, @spor_cond_7 float, @spor_cond_8 float, @spor_cond_9 float, @spor_cond_10 float, @comanda char(20), @tipop int,  @stergere int=0)
as
declare @ore_realcom int, @nrcom int
if @tipop=0  /*insert*/
	insert into pontaj (Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru, Salar_orar, 
		Ore_lucrate, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, 
		Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, 
		Ore_concediu_fara_salar, Ore_donare_sange, Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, 
		Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, 
		Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)
	values(@data, @marca, @numar_curent, @loc_de_munca, @loc_munca_pentru_stat_de_plata, @tip_salarizare, @regim_de_lucru, @salar_orar, 
		@ore_regie+@ore_acord, @ore_regie, @ore_acord, @ore_suplimentare_1, @ore_suplimentare_2, @ore_suplimentare_3, @ore_suplimentare_4, @ore_spor_100, 
		@ore_de_noapte, @ore_intrerupere_tehnologica, @ore_concediu_de_odihna, @ore_concediu_medical, @ore_invoiri, @ore_nemotivate, @ore_obligatii_cetatenesti, 
		@ore_concediu_fara_salar, @ore_donare_sange, @salar_categoria_lucrarii, @coeficient_acord, @realizat, @coeficient_de_timp, @ore_realizate_acord, 
		@sistematic_peste_program, @ore_sistematic_peste_program, @spor_specific, @spor_conditii_1, @spor_conditii_2, @spor_conditii_3, @spor_conditii_4, @spor_conditii_5, @spor_conditii_6, 
		@ore__cond_1, @ore__cond_2, @ore__cond_3, @ore__cond_4, @ore__cond_5, @ore__cond_6, @grupa_de_munca, @ore, @spor_cond_7, @spor_cond_8, @spor_cond_9, @spor_cond_10)
else /*update pe fiecare camp unde valoarea e mai mare decat -1,sau nu este egala cu '' exceptie loc de munca ptr stat*/
	update	pontaj
	set ore_regie=(case when @ore_regie>-1 then @ore_regie else ore_regie end),
	ore_acord=(case when @ore_acord>-1 then @ore_acord else ore_acord end),
	--ore_lucrate=(case when @ore_lucrate>-1 then @ore_lucrate else ore_lucrate end),
	ore_lucrate=(case when @ore_regie>-1 then @ore_regie else ore_regie end)+(case when @ore_acord>-1 then @ore_acord else ore_acord end),
	ore_suplimentare_1=(case when @ore_suplimentare_1>-1 then @ore_suplimentare_1 else ore_suplimentare_1 end),
	ore_suplimentare_2=(case when @ore_suplimentare_2>-1 then @ore_suplimentare_2 else ore_suplimentare_2 end),
	ore_suplimentare_3=(case when @ore_suplimentare_3>-1 then @ore_suplimentare_3 else ore_suplimentare_3 end),
	ore_suplimentare_4=(case when @ore_suplimentare_4>-1 then @ore_suplimentare_4 else ore_suplimentare_4 end),
	ore_spor_100=(case when @ore_spor_100>-1 then @ore_spor_100 else ore_spor_100 end),
	ore_de_noapte=(case when @ore_de_noapte>-1 then @ore_de_noapte else ore_de_noapte end),
	ore_intrerupere_tehnologica=(case when @ore_intrerupere_tehnologica>-1 then @ore_intrerupere_tehnologica else ore_intrerupere_tehnologica end),
	ore_concediu_de_odihna=(case when @ore_concediu_de_odihna>-1 then @ore_concediu_de_odihna else ore_concediu_de_odihna end),
	ore_concediu_medical=(case when @ore_concediu_medical>-1 then @ore_concediu_medical else ore_concediu_medical end),
	ore_invoiri=(case when @ore_invoiri>-1 then @ore_invoiri else ore_invoiri end),
	ore_nemotivate=(case when @ore_nemotivate>-1 then @ore_nemotivate else ore_nemotivate end),
	ore_obligatii_cetatenesti=(case when @ore_obligatii_cetatenesti>-1 then @ore_obligatii_cetatenesti else ore_obligatii_cetatenesti end),
	ore_concediu_fara_salar=(case when @ore_concediu_fara_salar>-1 then @ore_concediu_fara_salar else ore_concediu_fara_salar end),
	ore_donare_sange=(case when @ore_donare_sange>-1 then @ore_donare_sange else ore_donare_sange end),
	salar_categoria_lucrarii=(case when @salar_categoria_lucrarii>-1 then @salar_categoria_lucrarii else salar_categoria_lucrarii end),
	coeficient_de_timp=(case when @coeficient_de_timp>-1 then @coeficient_de_timp else coeficient_de_timp end),
	ore_realizate_acord=(case when @ore_realizate_acord>-1 then @ore_realizate_acord else ore_realizate_acord end),
	sistematic_peste_program=(case when @sistematic_peste_program>-1 then @sistematic_peste_program else sistematic_peste_program end),
	ore_sistematic_peste_program=(case when @ore_sistematic_peste_program>-1 then @ore_sistematic_peste_program else ore_sistematic_peste_program end),
	spor_specific=(case when @spor_specific>-1 then @spor_specific else spor_specific end),
	spor_conditii_1=(case when @spor_conditii_1>-1 then @spor_conditii_1 else spor_conditii_1 end),
	spor_conditii_2=(case when @spor_conditii_2>-1 then @spor_conditii_2 else spor_conditii_2 end),
	spor_conditii_3=(case when @spor_conditii_3>-1 then @spor_conditii_3 else spor_conditii_3 end),
	spor_conditii_4=(case when @spor_conditii_4>-1 then @spor_conditii_4 else spor_conditii_4 end),
	spor_conditii_5=(case when @spor_conditii_5>-1 then @spor_conditii_5 else spor_conditii_5 end),
	spor_conditii_6=(case when @spor_conditii_6>-1 then @spor_conditii_6 else spor_conditii_6 end),
	ore__cond_1=(case when @ore__cond_1>-1 then @ore__cond_1 else ore__cond_1 end),
	ore__cond_2=(case when @ore__cond_2>-1 then @ore__cond_2 else ore__cond_2 end),
	ore__cond_3=(case when @ore__cond_3>-1 then @ore__cond_3 else ore__cond_3 end),
	ore__cond_4=(case when @ore__cond_4>-1 then @ore__cond_4 else ore__cond_4 end),
	ore__cond_5=(case when @ore__cond_5>-1 then @ore__cond_5 else ore__cond_5 end),
	ore__cond_6=(case when @ore__cond_6>-1 then @ore__cond_6 else ore__cond_6 end),
	ore=(case when @ore>-1 then @ore else ore end),
	spor_cond_7=(case when @spor_cond_7>-1 then @spor_cond_7 else spor_cond_7 end),
	spor_cond_8=(case when @spor_cond_8>-1 then @spor_cond_8 else spor_cond_8 end),
	spor_cond_9=(case when @spor_cond_9>-1 then @spor_cond_9 else spor_cond_9 end),
	spor_cond_10=(case when @spor_cond_10>-1 then @spor_cond_10 else spor_cond_10 end),
	loc_de_munca=(case when @loc_de_munca<>'' then @loc_de_munca else loc_de_munca end),
	loc_munca_pentru_stat_de_plata=@loc_munca_pentru_stat_de_plata,
	tip_salarizare=(case when @tip_salarizare<>'' then @tip_salarizare else tip_salarizare end),
	regim_de_lucru=(case when @regim_de_lucru>-1 then @regim_de_lucru else regim_de_lucru end),
	salar_orar=(case when @salar_orar>-1 then @salar_orar else salar_orar end),
	coeficient_acord=(case when @coeficient_acord>-1 then @coeficient_acord else coeficient_acord end),
	realizat=(case when @realizat>-1 then @realizat else realizat end),
	grupa_de_munca=(case when @grupa_de_munca<>'' then @grupa_de_munca else grupa_de_munca end)
	where data=@data and marca=@marca and numar_curent=@numar_curent and loc_de_munca=@loc_de_munca

select @ore_realcom=ore_regie+ore_acord from pontaj where data=@data and marca=@marca and numar_curent=@numar_curent and loc_de_munca=@loc_de_munca
set @nrcom=(select count(marca) from realcom where data=@data and marca=@marca and numar_document='PS'+rtrim(convert(char(10),@numar_curent)))
if @nrcom>0
	if @ore_realcom=0 and 1=0 -- am scos linia de mai jos pt. a nu sterge pozitiile din realcom, pozitiile care nu au ore regie+acord
		delete from realcom where data=@data and Marca=@marca and Numar_document='PS'+rtrim(convert(char(10),@numar_curent))
	else
		update realcom
		set cantitate=@ore_realcom where data=@data and marca=@marca and numar_document='PS'+rtrim(convert(char(10),@numar_curent))

if @comanda<>''
	if @tipop=0 and not exists (select 1 from realcom where data=@data and Marca=@marca and Numar_document='PS'+rtrim(convert(char(10),@numar_curent)) and comanda=@comanda)
		insert into realcom (Marca, Loc_de_munca, Numar_document, Data,Comanda, Cod_reper, Cod,Cantitate, Categoria_salarizare, Norma_de_timp, Tarif_unitar)
		select @marca, @loc_de_munca, 'PS'+rtrim(convert(char(10),@numar_curent)), @data, @comanda, '', '', @ore_realcom, 1, 0, @Salar_orar
	else
		update realcom
		set cantitate=@ore_realcom where data=@data and marca=@marca and numar_document='PS'+rtrim(convert(char(10),@numar_curent)) and comanda=@comanda

exec verificaPontaj @data, @marca, @numar_curent, @loc_de_munca, @stergere
