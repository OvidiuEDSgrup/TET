--***
/**	procedura flut. det. retineri	*/
Create procedure ptFluturasi (@cTerm char(10), @sesiune varchar(50)=null)
as
begin

	declare @cMarca char(6), @cLocm_jos char(9), @cLocm_sus char(9), @cFunctie char(6), @cGrupa_de_munca char(1), @lGrupa_de_munca_exceptata int, 
	@Data_jos datetime, @Data_sus datetime, @nMod_plata int, @cMod_plata char(20), @nTip_stat int, @cTip_stat char(30), 
	@nMarca int, @nLocm int, @nFunctie int, @nGrupa_de_munca int, @Un_sir_de_marci bit, @Sir_marci char(200), @Rest_plata_poz int, @utilizator varchar(10)

	delete from par where Tip_parametru='PS' and Parametru='FLUT_1CL'
	insert into par (Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica)
	select 'PS', 'FLUT_1CL', 'FLUT_1CL', 1, 0, ''

	set @utilizator=dbo.fIaUtilizator(@sesiune)	

	Set @cMarca = isnull((select Numar from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='FS'),'')
	Set @nMarca = (case when @cMarca<>'' then 1 else 0 end)
	Set @cLocm_jos = rtrim(isnull((select Loc_munca from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),''))
	Set @cLocm_sus = rtrim(isnull((select Loc_munca from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),''))+'ZZZ'
	Set @nLocm = (case when @cLocm_jos<>'' then 1 else 0 end)
	Set @cFunctie = isnull((select Cod_gestiune from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @nFunctie = (case when @cFunctie<>'' then 1 else 0 end)
	Set @cGrupa_de_munca = isnull((select valuta from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @nGrupa_de_munca = (case when @cGrupa_de_munca<>'' then 1 else 0 end)
	Set @lGrupa_de_munca_exceptata = isnull((select curs from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @cMod_plata = isnull((select Cod_tert from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @nMod_plata = (case when @cMod_plata<>'' then 1 else 0 end)
	Set @cTip_stat = isnull((select Comanda from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @nTip_stat = (case when @cTip_stat<>'' then 1 else 0 end)
	Set @Data_jos = isnull((select Data_facturii from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set	@Data_sus = isnull((select Data from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),'')
	Set @Un_sir_de_marci = (case when rtrim(isnull((select val_alfanumerica from par where tip_parametru='PS' and parametru=rtrim(host_id())+'S'),''))<>'' then 1 else 0 end)
	Set @Sir_marci = rtrim(isnull((select val_alfanumerica from par where tip_parametru='PS' and parametru=rtrim(host_id())+'S'),''))
	Set @Rest_plata_poz = isnull((select Discount from avnefac where Avnefac.Terminal=@cTerm and tip='FS'),0)

--	am inlocuit in apelarea procedurii -> @cTerm cu utilizator
	exec fluturasi_detaliere_retineri @utilizator, @Data_jos, @Data_sus, 'Nume', @nMarca, @cMarca, @cMarca, @nLocm, @cLocm_jos, @cLocm_sus, @nFunctie, @cFunctie, 
	@nGrupa_de_munca,@cGrupa_de_munca, @lGrupa_de_munca_exceptata, 1, 'T', 0, '', @Rest_plata_poz, @nTip_stat, @cTip_stat, @Un_sir_de_marci, @Sir_marci, @nMod_plata, @cMod_plata, 0, 0, ''

	delete from par where Tip_parametru='PS' and Parametru='FLUT_1CL'

end
