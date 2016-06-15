create procedure yso_xImportTargetag as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select Agent=ISNULL(Agent,'')
		, Denumire_agent=RTRIM(Denumire_agent)
		, Client=RTRIM(Client)
		, Denumire_client=RTRIM(Denumire_client)
		, Grupa_produs=RTRIM(Grupa_produs)
		, Denumire_grupa=RTRIM(Denumire_grupa)
		, Data_lunii=RTRIM(Data_lunii)
		, Cantitate_valoare=RTRIM(Cantitate_valoare)
		,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct Agent
		, Client
		, Grupa_produs
		, Data_lunii
		, Cantitate_valoare 
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select	
		Agent
		, Client
		, Grupa_produs
		, Data_lunii
		, Cantitate_valoare 
	from yso_vIaTargetag
