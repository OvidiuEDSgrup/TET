--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga o categorie de indicatori 
verificand unicitatea codului*/

CREATE procedure  [dbo].[wScriuMasini]  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(10), @o_cod varchar(20), @tipauto varchar(50), 
		@marca varchar(50), @model varchar(50), @versiune varchar(50), @tipmotor varchar(50),
		@anfabricatie varchar(50), @carburant varchar(50), @dealer varchar(50), @seriesasiu varchar (50),
		@nrcirculatie varchar(50), @seriedemotor varchar(50), @kmlabord float, @DAM varchar(50), @DDG datetime,
		@cilindree varchar(50), @culoare varchar(50), @denumireculoare varchar(50), 
	    @codantidemaraj varchar(50), @codradio varchar(50), @codchei varchar(50), @tipclub varchar(50), 
	    @numarcard varchar(50), @datacard datetime, @dataadeziunii datetime, @codchirias varchar(50), 
	    @codproprietar varchar(50), @dataITP datetime, @asigurare varchar(50), @asigurareobligatorie varchar(50), 
	    @datacumpararii datetime, @observatii varchar(50), @nrcomanda varchar(50),
	    @puteremotor varchar(50), @garantie real, @furnizor varchar(50), @localitatefurnizor varchar(50), 
	    @moddeplata varchar(50), @denumirefirmaleasing varchar(50)


set @cod= rtrim(isnull(@parXML.value('(/row/@codautovehicul)[1]', 'varchar(10)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(10)'), ''))
set	@tipauto= rtrim(isnull(@parXML.value('(/row/@tipauto)[1]', 'varchar(50)'), ''))
set	@marca = rtrim(isnull(@parXML.value('(/row/@marca)[1]', 'varchar(50)'), ''))
set	@model = rtrim(isnull(@parXML.value('(/row/@model)[1]', 'varchar(50)'), ''))
set	@versiune= rtrim(isnull(@parXML.value('(/row/@versiune)[1]', 'varchar(50)'), ''))
set	@tipmotor = rtrim(isnull(@parXML.value('(/row/@tipmotor)[1]', 'varchar(50)'), ''))
set @anfabricatie= rtrim(isnull(@parXML.value('(/row/@anfabricatie)[1]', 'varchar(10)'), ''))
set	@carburant = rtrim(isnull(@parXML.value('(/row/@carburant)[1]', 'varchar(50)'), ''))
set	@dealer = rtrim(isnull(@parXML.value('(/row/@dealer)[1]', 'varchar(50)'), ''))
set	@seriesasiu = rtrim(isnull(@parXML.value('(/row/@seriesasiu)[1]', 'varchar(50)'), ''))
set	@nrcirculatie = rtrim(isnull(@parXML.value('(/row/@nrcirculatie)[1]', 'varchar(50)'), ''))
set	@seriedemotor = rtrim(isnull(@parXML.value('(/row/@seriedemotor)[1]', 'varchar(50)'), ''))
set	@kmlabord = rtrim(isnull(@parXML.value('(/row/@kmlabord)[1]', 'float'), ''))
set	@DAM = rtrim(isnull(@parXML.value('(/row/@DAM)[1]', 'varchar(50)'), ''))
set	@DDG = rtrim(isnull(@parXML.value('(/row/@DDG)[1]', 'datetime'), '01/01/1901'))
set	@cilindree = rtrim(isnull(@parXML.value('(/row/@cilindre)[1]', 'varchar(50)'), ''))
set	@culoare = rtrim(isnull(@parXML.value('(/row/@culoare)[1]', 'varchar(50)'), ''))
set	@denumireculoare= rtrim(isnull(@parXML.value('(/row/@denumireculoare)[1]', 'varchar(50)'), ''))
set	@codantidemaraj = rtrim(isnull(@parXML.value('(/row/@codantidemaraj)[1]', 'varchar(50)'), ''))
set	@codradio= rtrim(isnull(@parXML.value('(/row/@codradio)[1]', 'varchar(50)'), ''))
set	@codchei = rtrim(isnull(@parXML.value('(/row/@codchei)[1]', 'varchar(50)'), ''))
set	@tipclub = rtrim(isnull(@parXML.value('(/row/@tipclub)[1]', 'varchar(50)'), ''))
set	@numarcard = rtrim(isnull(@parXML.value('(/row/@numarcard)[1]', 'varchar(50)'), ''))
set	@datacard = rtrim(isnull(@parXML.value('(/row/@datacard)[1]', 'datetime'), '01/01/1901'))
set	@dataadeziunii = rtrim(isnull(@parXML.value('(/row/@dataadeziunii)[1]', 'varchar(50)'), ''))
set	@codchirias = rtrim(isnull(@parXML.value('(/row/@codchirias)[1]', 'varchar(50)'), ''))
set	@codproprietar = rtrim(isnull(@parXML.value('(/row/@codproprietar)[1]', 'varchar(50)'), ''))
set	@dataITP = rtrim(isnull(@parXML.value('(/row/@dataITP)[1]', 'datetime'), '01/01/1901'))
set	@asigurare= rtrim(isnull(@parXML.value('(/row/@asigurare)[1]', 'varchar(50)'), ''))
set	@asigurareobligatorie = rtrim(isnull(@parXML.value('(/row/@asigurareobligatorie)[1]', 'varchar(50)'), ''))
set	@datacumpararii = rtrim(isnull(@parXML.value('(/row/@datacumpararii)[1]', 'datetime'), '01/01/1901'))
set	@observatii = rtrim(isnull(@parXML.value('(/row/@observatii)[1]', 'varchar(50)'), ''))
set	@nrcomanda = rtrim(isnull(@parXML.value('(/row/@nrcomanda)[1]', 'varchar(50)'), ''))
set	@tipmotor = rtrim(isnull(@parXML.value('(/row/@tipmotor)[1]', 'varchar(50)'), ''))
set	@puteremotor = rtrim(isnull(@parXML.value('(/row/@puteremotor)[1]', 'varchar(50)'), ''))
set	@garantie = rtrim(isnull(@parXML.value('(/row/@garantie)[1]', 'real'), ''))
set	@furnizor = rtrim(isnull(@parXML.value('(/row/@furnizor)[1]', 'varchar(50)'), ''))
set	@localitatefurnizor = rtrim(isnull(@parXML.value('(/row/@localitatefurnizor)[1]', 'varchar(50)'), ''))
set	@moddeplata = rtrim(isnull(@parXML.value('(/row/@moddeplata)[1]', 'varchar(50)'), ''))
set	@denumirefirmaleasing = rtrim(isnull(@parXML.value('(/row/@denumirefirmaleasing)[1]', 'varchar(50)'), ''))

if isnull((select top 1 val_logica from par where Tip_parametru='SA' and Parametru='CODASSAS '),0)=1 --Cod auto egal serie de sasiu, citita din PAR
begin
	set @cod=@seriesasiu
end

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
    if @modificare=1
begin
	update auto set Cod=@cod, Tip_auto=@tipauto, An_fabricatie=@anfabricatie, Carburant=@carburant, Culoare=@culoare, 
	                Tip_motor=@tipmotor, Marca=@marca, Model=@model, Versiune=@versiune,Nr_circulatie=@nrcirculatie, Serie_de_sasiu=@seriesasiu,
	                Putere_motor=@puteremotor, Cod_proprietar=@codproprietar
	where Cod=@seriesasiu 
	 	    	    	    
	return
end


--Aici incepe partea de adaugare

if exists(select Cod from auto where Cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;
end	

else
	insert into auto(Cod, Tip_auto, Marca, Model, Versiune, An_fabricatie, Carburant, Dealer, Serie_de_sasiu, Nr_circulatie, 
		Serie_de_motor, Km_la_bord, DAM, DDG, Cilindree, Culoare, Denumire_culoare, Cod_antidemaraj, 
		Cod_radio, Cod_chei, Tip_club, Numar_card, Data_card, Data_adeziunii, Cod_chirias, Cod_proprietar, 
		Data_ITP, Asigurare, Asigurare_obligatorie, Data_cumpararii, Observatii, Nr_comanda, Tip_motor, 
		Putere_motor, Garantie, Furnizor, Localitate_furnizor, Mod_de_plata, Denumire_firma_leasing)
		
	 VALUES (@cod, @tipauto, @marca, @model, @versiune, @anfabricatie, @carburant, @dealer, @seriesasiu,
	 @nrcirculatie, @seriedemotor, @kmlabord, @DAM, @DDG, @cilindree, @culoare, @denumireculoare, 
	 @codantidemaraj, @codradio, @codchei, @tipclub, @numarcard, @datacard, @dataadeziunii, @codchirias, @codproprietar, 
	 @dataITP, @asigurare, @asigurareobligatorie, @datacumpararii, @observatii, @nrcomanda, @tipmotor, 
	 @puteremotor, @garantie, @furnizor, @localitatefurnizor, @moddeplata, @denumirefirmaleasing)
