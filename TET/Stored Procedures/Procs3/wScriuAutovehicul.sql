--***

CREATE procedure  wScriuAutovehicul  @sesiune varchar(50), @parXML XML
as
declare @codautovehicul varchar(20), @o_codautovehicul varchar(20), @tipautovehicul varchar(50), 
		@marca varchar(50), @model varchar(50), @versiune varchar(50), @tipmotor varchar(50),
		@anfabricatie varchar(50), @carburant varchar(50), @dealer varchar(50), @seriesasiu varchar(50),
		@nrinmatriculare varchar(50), @seriemotor varchar(50), @kmbord float, @DAM varchar(50), 
		@DDG datetime,	@cilindree varchar(50), @culoare varchar(50), @denumireculoare varchar(50), 
	    @codantidemaraj varchar(50), @codradio varchar(50), @codchei varchar(50), @tipclub varchar(50), 
	    @nrcard varchar(50), @datacard datetime, @dataadeziunii datetime, @codchirias varchar(50), 
	    @codproprietar varchar(50), @dataITP datetime, @obs varchar(50), @asigurare varchar(50), 
	    @asigurareobligatorie varchar(50), @datacumpararii datetime, @com varchar(50),
	    @puteremotor varchar(50), @garantie float, @furnizor varchar(50), 
	    @localitatefurnizor varchar(50), @modplata varchar(50), @firmaleasing varchar(50), 
	    @update int

set @codautovehicul= rtrim(isnull(@parXML.value('(/row/@codautovehicul)[1]', 'varchar(20)'), ''))
set @o_codautovehicul= rtrim(isnull(@parXML.value('(/row/@o_codautovehicul)[1]', 'varchar(20)'), ''))
set	@tipautovehicul= rtrim(isnull(@parXML.value('(/row/@tipautovehicul)[1]', 'varchar(50)'), ''))
set	@marca = rtrim(isnull(@parXML.value('(/row/@marca)[1]', 'varchar(50)'), ''))
set	@model = rtrim(isnull(@parXML.value('(/row/@model)[1]', 'varchar(50)'), ''))
set	@versiune= rtrim(isnull(@parXML.value('(/row/@versiune)[1]', 'varchar(50)'), ''))
set	@tipmotor = rtrim(isnull(@parXML.value('(/row/@tipmotor)[1]', 'varchar(50)'), ''))
set @anfabricatie= rtrim(isnull(@parXML.value('(/row/@anfabricatie)[1]', 'varchar(10)'), ''))
set	@carburant = rtrim(isnull(@parXML.value('(/row/@carburant)[1]', 'varchar(50)'), 'B'))
set	@dealer = rtrim(isnull(@parXML.value('(/row/@dealer)[1]', 'varchar(50)'), ''))
set	@nrinmatriculare = rtrim(isnull(@parXML.value('(/row/@nrinmatriculare)[1]', 'varchar(50)'), ''))
set	@seriesasiu = rtrim(isnull(@parXML.value('(/row/@seriesasiu)[1]', 'varchar(50)'), ''))
set	@seriemotor = rtrim(isnull(@parXML.value('(/row/@seriemotor)[1]', 'varchar(50)'), ''))
set	@kmbord = rtrim(isnull(@parXML.value('(/row/@kmbord)[1]', 'float'), 0))
set	@DAM = rtrim(isnull(@parXML.value('(/row/@DAM)[1]', 'varchar(50)'), ''))
set	@DDG = rtrim(isnull(@parXML.value('(/row/@DDG)[1]', 'datetime'), '01/01/1901'))
set	@cilindree = rtrim(isnull(@parXML.value('(/row/@cilindree)[1]', 'varchar(50)'), ''))
set	@culoare = rtrim(isnull(@parXML.value('(/row/@culoare)[1]', 'varchar(50)'), ''))
set	@denumireculoare= rtrim(isnull(@parXML.value('(/row/@denumireculoare)[1]', 'varchar(50)'), ''))
set	@codantidemaraj = rtrim(isnull(@parXML.value('(/row/@codantidemaraj)[1]', 'varchar(50)'), ''))
set	@codradio= rtrim(isnull(@parXML.value('(/row/@codradio)[1]', 'varchar(50)'), ''))
set	@codchei = rtrim(isnull(@parXML.value('(/row/@codchei)[1]', 'varchar(50)'), ''))
set	@tipclub = rtrim(isnull(@parXML.value('(/row/@tipclub)[1]', 'varchar(50)'), ''))
set	@nrcard = rtrim(isnull(@parXML.value('(/row/@nrcard)[1]', 'varchar(50)'), ''))
set	@datacard = rtrim(isnull(@parXML.value('(/row/@datacard)[1]', 'datetime'), '01/01/1901'))
set	@dataadeziunii = rtrim(isnull(@parXML.value('(/row/@dataadeziunii)[1]', 'datetime'), '01/01/1901'))
set	@codchirias = rtrim(isnull(@parXML.value('(/row/@codchirias)[1]', 'varchar(50)'), ''))
set	@codproprietar = rtrim(isnull(@parXML.value('(/row/@codproprietar)[1]', 'varchar(50)'), ''))
set	@dataITP = rtrim(isnull(@parXML.value('(/row/@dataITP)[1]', 'datetime'), '01/01/1901'))
set	@asigurare= rtrim(isnull(@parXML.value('(/row/@asigurare)[1]', 'varchar(50)'), ''))
set	@asigurareobligatorie = rtrim(isnull(@parXML.value('(/row/@asigurareobligatorie)[1]', 'varchar(50)'), ''))
set	@datacumpararii = rtrim(isnull(@parXML.value('(/row/@datacumpararii)[1]', 'datetime'), '01/01/1901'))
set	@obs = rtrim(isnull(@parXML.value('(/row/@obs)[1]', 'varchar(50)'), ''))
set	@com = rtrim(isnull(@parXML.value('(/row/@com)[1]', 'varchar(50)'), ''))
set	@puteremotor = rtrim(isnull(@parXML.value('(/row/@puteremotor)[1]', 'varchar(50)'), ''))
set	@garantie = rtrim(isnull(@parXML.value('(/row/@garantie)[1]', 'float'), 0))
set	@furnizor = rtrim(isnull(@parXML.value('(/row/@furnizor)[1]', 'varchar(50)'), ''))
set	@localitatefurnizor = rtrim(isnull(@parXML.value('(/row/@localitatefurnizor)[1]', 'varchar(50)'), ''))
set	@modplata = rtrim(isnull(@parXML.value('(/row/@modplata)[1]', 'varchar(50)'), ''))
set	@firmaleasing = rtrim(isnull(@parXML.value('(/row/@firmaleasing)[1]', 'varchar(50)'), ''))
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if isnull(@seriesasiu,'')<>'' and isnull((select top 1 val_logica from par where Tip_parametru='SA' and Parametru='CODASSAS'),0)=1 
begin
	set @codautovehicul=@seriesasiu --Cod auto = serie de sasiu din par
end

if @update=1 and isnull(@codautovehicul,'')<>@o_codautovehicul and exists (select 1 from devauto where Autovehicul=@o_codautovehicul)
begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
end
	
if (@update=0 or @update=1 and isnull(@codautovehicul,'')<>@o_codautovehicul) and exists (select 1 from auto where cod=@codautovehicul)
begin
		raiserror('Acest cod exista deja!',11,1)
		return
end

if isnull(@codautovehicul,'')='' 
begin
		raiserror('Cod necompletat!',11,1)
		return
end

if isnull(@seriesasiu,'')='' 
begin
		raiserror('Serie sasiu necompletata!',11,1)
		return
end

if not exists (select 1 from terti where tert=isnull(@codproprietar,'')) 
begin
		raiserror('Proprietar inexistent!',11,1)
		return
end

if isnull(@codchirias,'')<>'' and not exists (select 1 from terti where tert=isnull(@codchirias,'')) 
begin
		raiserror('Chirias inexistent!',11,1)
		return
end

--Aici incepe partea de modificare
if @update=1
begin
	update auto set Cod=@codautovehicul, 
		Tip_auto=@tipautovehicul, Marca=@marca, Model=@model, Versiune=@versiune, 
		An_fabricatie=@anfabricatie, Carburant=@carburant, Dealer=@dealer, Serie_de_sasiu=@seriesasiu, 
		Nr_circulatie=@nrinmatriculare, Serie_de_motor=@seriemotor, Km_la_bord=@kmbord, DAM=@DAM, 
		DDG=@DDG, Cilindree=@cilindree, Culoare=@culoare, Denumire_culoare=@denumireculoare, 
		Cod_antidemaraj=@codantidemaraj, Cod_radio=@codradio, Cod_chei=@codchei, Tip_club=@tipclub, 
		Numar_card=@nrcard, Data_card=@datacard, Data_adeziunii=@dataadeziunii, 
		Cod_chirias=@codchirias, Cod_proprietar=@codproprietar, Data_ITP=@dataitp, 
		Asigurare=@asigurare, Asigurare_obligatorie=@asigurareobligatorie, 
		Data_cumpararii=@datacumpararii, Observatii=@obs, Nr_comanda=@com, Tip_motor=@tipmotor, 
		Putere_motor=@puteremotor, Garantie=@garantie, Furnizor=@furnizor, 
		Localitate_furnizor=@localitatefurnizor, Mod_de_plata=@modplata, 
		Denumire_firma_leasing=@firmaleasing
		where Cod=@o_codautovehicul
end
--Aici incepe partea de adaugare
else
begin
	/*if exists(select 1 from auto where Cod=@codautovehicul)
	begin
			declare @err varchar(100)
			set @err = (select 'Codul '+@codautovehicul+' exista deja!')
			RAISERROR(@err,16,1)
			return ;
	end	

	else*/
		insert into auto(Cod, Tip_auto, Marca, Model, Versiune, An_fabricatie, Carburant, Dealer, 
			Serie_de_sasiu, Nr_circulatie, Serie_de_motor, Km_la_bord, DAM, DDG, Cilindree, Culoare, 
			Denumire_culoare, Cod_antidemaraj, Cod_radio, Cod_chei, Tip_club, Numar_card, Data_card, 
			Data_adeziunii, Cod_chirias, Cod_proprietar, Data_ITP, Asigurare, Asigurare_obligatorie, 
			Data_cumpararii, Observatii, Nr_comanda, Tip_motor, Putere_motor, Garantie, Furnizor, 
			Localitate_furnizor, Mod_de_plata, Denumire_firma_leasing)
			VALUES (@codautovehicul, @tipautovehicul, @marca, @model, @versiune, @anfabricatie, 
			@carburant, @dealer, @seriesasiu, @nrinmatriculare, @seriemotor, @kmbord, @DAM, @DDG, 
			@cilindree, @culoare, @denumireculoare, @codantidemaraj, @codradio, @codchei, @tipclub, 
			@nrcard, @datacard, @dataadeziunii, @codchirias, @codproprietar, @dataITP, @asigurare, 
			@asigurareobligatorie, @datacumpararii, @obs, @com, @tipmotor, 
			@puteremotor, @garantie, @furnizor, @localitatefurnizor, @modplata, @firmaleasing)
end
--go
