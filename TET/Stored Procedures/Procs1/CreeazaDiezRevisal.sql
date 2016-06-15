create procedure CreeazaDiezRevisal @numeTabela varchar(100), @data datetime=null, @marca varchar(6)=null
AS
--	tabela utilizata in procedurile de generare Revisal (genRevisal si genRevisalContracte)
if @numeTabela='#RevisalContracte'
Begin
	alter table #RevisalContracte
		add Data datetime, Marca char(6), CNP varchar(13), CNPVechi varchar(13), DataAngajarii datetime, Loc_de_munca varchar(30), 
		DataPlecarii datetime, Cod_functie varchar(6), CodCOR varchar(6), CodCORAnt varchar(6), DenumireCOR varchar(250), 
		TipDurata varchar(50), TipDurataAnt varchar(50), TipNorma varchar(50), TipNormaAnt varchar(50), 
		TipContract varchar(50), Durata int, DurataAnt int, IntervalTimp varchar(50), Norma varchar(50), NormaAnt varchar(50), 
		Repartizare varchar(50), NumarContract varchar(20), NumarContractVechi varchar(20), DataContractVechi datetime, DataInceputContract datetime, DataSfarsitContract datetime, ExceptieDataSfarsit varchar(20), 
		Salar float, TemeiIncetare varchar(50), DataIncetareContract datetime, TemeiReactivare varchar(50), DataReactivare datetime, 
		TextTemeiIncetare varchar(100), DetaliiContract varchar(100), DataIncheiereContract datetime, StareCurenta varchar(50), 
		DataIncStareCurenta datetime, StarePrecedenta varchar(50), DataIncetareStarePrecedenta datetime, DataConsemnare datetime, TemeiLegal varchar(50)
	--Create index RevisalContracte on #RevisalContracte (NrCrt, Data, Marca, NumarContract)
end

if @numeTabela='#RevisalSalariati'
Begin
	alter table #RevisalSalariati 
		add Data datetime, Marca varchar(6), Nume varchar(50), Prenume varchar(50), NumeAnt varchar(50), PrenumeAnt varchar(50), CNP varchar(13), CNPVechi varchar(13), 
		Cetatenie varchar(50), Nationalitate nvarchar(80), TipActIdentitate varchar(50), Mentiuni varchar(1000), CodSiruta varchar(6), Adresa varchar(1000), AdresaAnt varchar(1000), 
		Localitate varchar(30), DataConsemnarii datetime, TipAutorizatie varchar(50), DataInceputAutorizatie datetime, DataSfarsitAutorizatie datetime
	
	--Create index RevisalSalariati on #RevisalSalariati (NrCrt, Data, Marca, CNP)
	Create index cnp on #RevisalSalariati (cnp)
End

if @numeTabela='#StareContracte'
Begin
	alter table #StareContracte
		add Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
			AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate nvarchar(50)
		Create index Principal on #StareContracte (Data, Marca, StareContract, DataInceput)
End

if @numeTabela='#extinfop' 
Begin
	if @data is null
	Begin
		alter table #extinfop
			add Cod_inf char(13) not null, Val_inf nvarchar(80) not null, Data_inf datetime not null, Procent float not null
		create index principal on #extinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
	End
End
