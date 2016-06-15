--***
Create 
procedure wValidareDateRevisal (@sesiune varchar(50), @document xml)
as 
begin
	declare @data datetime, @data_veche datetime, @marca varchar(6), @nrcontract varchar(20), 
	@cetatenie varchar(60), @nationalitate varchar(60), @localitate varchar(6), @TipContract varchar(60), @exceptieDataSfarsit varchar(60),
	@repartizaretm varchar(60), @intervalreptm varchar(60), @nroreint int, @dataconsemn datetime, @grupa_de_munca char(1), @mod_angajare char(1)

	set @data=isnull(@document.value('(/row/row/@data)[1]','datetime'),0) 
	set @marca=isnull(@document.value('(/row/@marca)[1]','varchar(6)'),'')
	set @nrcontract=isnull(@document.value('(/row/row/@nrcontract)[1]','varchar(20)'),'')
	set @cetatenie=isnull(@document.value('(/row/row/@cetatenie)[1]','varchar(60)'),'')
	set @nationalitate=isnull(@document.value('(/row/row/@nationalitate)[1]','varchar(60)'),'')
	set @localitate=isnull(@document.value('(/row/row/@localitate)[1]','varchar(6)'),'')
	set @TipContract=isnull(@document.value('(/row/row/@tipcontract)[1]','varchar(60)'),'')
	set @exceptieDataSfarsit=isnull(@document.value('(/row/row/@excepdatasf)[1]','varchar(60)'),'')
	set @repartizaretm=isnull(@document.value('(/row/row/@repartizaretm)[1]','varchar(60)'),'')
	set @intervalreptm=isnull(@document.value('(/row/row/@intervalreptm)[1]','varchar(60)'),'')
	set @nroreint=isnull(@document.value('(/row/row/@nroreint)[1]','int'),0)
	set @dataconsemn=isnull(@document.value('(/row/row/@dataconsemn)[1]','datetime'),'01/01/1901') 
	select @grupa_de_munca=grupa_de_munca, @mod_angajare=mod_angajare from personal where marca=@marca
	
	if @document.exist('/row/row')=1 and @nrcontract=''
	begin
		raiserror('wValidareDateRevisal: Numar contract necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @TipContract=''
	begin
		raiserror('wValidareDateRevisal: Tip contract de munca necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @cetatenie<>'' and @cetatenie not in (select cod from CatalogRevisal where TipCatalog='Cetatenie')
	begin
		raiserror('wValidareDateRevisal: Cetatenie inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @nationalitate<>'' and @Nationalitate not in (select cod from CatalogRevisal where TipCatalog='Nationalitate')
	begin
		raiserror('wValidareDateRevisal: Nationalitate inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @localitate=''
	begin
		raiserror('wValidareDateRevisal: Localitate necompletata!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @localitate not in (select cod_oras from localitati)
	begin
		raiserror('wValidareDateRevisal: Localitate inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @mod_angajare='N' and @exceptieDataSfarsit<>''
	begin
		raiserror('wValidareDateRevisal: Exceptie data sfarsit se completeaza doar pt. salariatii angajati pe perioada determinata!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @repartizaretm=''
	begin
		raiserror('wValidareDateRevisal: Repartizare timp munca necompletata!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @intervalreptm in ('OrePeLuna','OrePeSaptamina','OrePeZi') and @Grupa_de_munca in ('N','D','S')
	begin
		raiserror('wValidareDateRevisal: Campul Interval repartizare timp munca trebuie completat doar pt. salariatii cu contract de munca cu timp partial!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @intervalreptm in ('OrePeLuna','OrePeSaptamina') and @nroreint=0
	begin
		raiserror('wValidareDateRevisal: Numar ore interval repartizare timp munca necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @dataconsemn='01/01/1901'
	begin
		raiserror('wValidareDateRevisal: Data consemnarii informatiei necompletata!',11,1)
		return -1
	end
end
