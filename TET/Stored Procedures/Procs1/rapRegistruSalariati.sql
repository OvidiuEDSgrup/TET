--***
Create procedure rapRegistruSalariati
	(@dataJos datetime, @dataSus datetime, @DataRegistru datetime, @marca char(6)=null, @locm char(9)=null, @grupare int=1, @stareSalariati int=0, @activitate varchar(20)=null)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	declare @oMarca int, @cMarca varchar(6), @unLm int, @Lm varchar(9)
	select @oMarca=(case when ISNULL(@marca,'')<>'' then 1 else 0 end), 
		@cMarca=ISNULL(@marca,''),
		@unLm=(case when ISNULL(@locm,'')<>'' then 1 else 0 end), 
		@Lm=ISNULL(@locm,'')
	
	exec genRevisal 
	@dataJos=@dataJos, 
	@dataSus=@dataSus, 
	@DataRegistru=@DataRegistru, -- data la care se doreste generarea registrului
	@oMarca=@oMarca, @cMarca=@cMarca, 	
	@unLm=@unLm, @Lm=@Lm, @strict=0, 
	@SirMarci='',	--	sir de marci
	@fltDataAngPl=0, @DataAngPlJ='', @DataAngPlS='', 
	@fltDataModif=0, @DataModifJ='', @DataModifS='', 
	@oSub=0, @cSub='', 
	@TipSocietate='SediuSocial', -- Tip societate (SediuSocial, Filiala, Sucursala)
	@ReprLegal='', -- reprezentant legal
	@cDirector='', -- cale generare fisier XML
	@inXML=0,
	@genRaport=1,	--	generare raport
	@grupare=@grupare,	--	grupare raport (1=Salariati,2-Locuri de munca)
	@stareSalariati=@stareSalariati,	--	filtrare raport (0 ->Toti salariatii, 1->Salariati activi, 2->Salariati suspendati 3->Salariati cu contract incetat)
	@activitate=@activitate

end try

begin catch
	set @eroare='Procedura rapRegistruSalariati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec rapStatDePersonal '07/01/2012', 'A013', null, 0, null, '', 'A', '', 'T', '3', 1, 0, 1
*/
