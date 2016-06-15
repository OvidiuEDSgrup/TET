CREATE TABLE [dbo].[infoconmed] (
    [Data]                        DATETIME   NOT NULL,
    [Marca]                       CHAR (6)   NOT NULL,
    [Data_inceput]                DATETIME   NOT NULL,
    [Serie_certificat_CM]         CHAR (10)  NOT NULL,
    [Nr_certificat_CM]            CHAR (10)  NOT NULL,
    [Serie_certificat_CM_initial] CHAR (10)  NOT NULL,
    [Nr_certificat_CM_initial]    CHAR (10)  NOT NULL,
    [Indemnizatie_FAMBP]          FLOAT (53) NOT NULL,
    [Zile_CAS]                    SMALLINT   NOT NULL,
    [Zile_FAMBP]                  SMALLINT   NOT NULL,
    [Cod_urgenta]                 CHAR (10)  NOT NULL,
    [Cod_boala_grpA]              CHAR (10)  NOT NULL,
    [Data_rez]                    DATETIME   NOT NULL,
    [Data_acordarii]              DATETIME   NOT NULL,
    [Cnp_copil]                   CHAR (13)  NOT NULL,
    [Loc_prescriere]              SMALLINT   NOT NULL,
    [Medic_prescriptor]           CHAR (50)  NOT NULL,
    [Unitate_sanitara]            CHAR (50)  NOT NULL,
    [Nr_aviz_me]                  CHAR (10)  NOT NULL,
    [Valoare]                     FLOAT (53) NOT NULL,
    [Valoare1]                    FLOAT (53) NOT NULL,
    [Alfa]                        CHAR (10)  NOT NULL,
    [Alfa1]                       CHAR (30)  NOT NULL,
    [Numar_pozitie]               INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[infoconmed]([Data] ASC, [Marca] ASC, [Data_inceput] ASC, [Numar_pozitie] ASC);


GO
--***
create trigger tr_ValidInfoconmed on infoconmed for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'INFOCONMED-Informatii concedii medicale' from inserted
	union all
	select DISTINCT Data, 'INFOCONMED-Informatii concedii medicale' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca)
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED 
		exec validMarcaSalarii
	end 

	if UPDATE(Serie_certificat_CM) or UPDATE(Nr_certificat_CM)	--	Verificam consistenta campurilor serie/numar certificat CM
	begin
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
			where c.Tip_diagnostic<>'0-' and i.Loc_prescriere<>0 and (i.Serie_certificat_CM='' or i.Nr_certificat_CM=''))
			raiserror('Eroare operare: Serie/numar certificat concediu medical necompletat!',16,1)
	end

	if UPDATE(Nr_certificat_CM)	--	Verificam existenta unui numar de certificat de CM introdus pe o alta marca
	begin
		if exists (select 1 from inserted i where i.Loc_prescriere<>0 and i.Nr_certificat_CM<>'') and not exists (select 1 from deleted) 
			and exists (select 1 from infoconmed ic 
				left outer join personal p on p.Marca=ic.Marca
				inner join inserted i on ic.Serie_certificat_CM=i.Serie_certificat_CM and ic.Nr_certificat_CM=i.Nr_certificat_CM
				left outer join personal p1 on p1.Marca=i.Marca	
			where (ic.Marca<>i.Marca or ic.Data_inceput<>i.Data_inceput) and p.Cod_numeric_personal<>p1.Cod_numeric_personal)
		Begin
			select @mesajeroare='Acest numar de certificat a mai fost introdus la marca: '+rtrim(ic.Marca)+', pe CM cu data de inceput: '+convert(char(10),ic.Data_inceput,103)+'!'
			from infoconmed ic inner join inserted i on ic.Serie_certificat_CM=i.Serie_certificat_CM and ic.Nr_certificat_CM=i.Nr_certificat_CM
			where (ic.Marca<>i.Marca or ic.Data_inceput<>i.Data_inceput)
			raiserror(@mesajeroare,16,1)
		End	
	end

	if UPDATE(Nr_certificat_CM_initial)	--	Verificam consistenta campurilor serie/numar certificat CM
	begin
		if exists (select 1 from inserted i where i.Loc_prescriere<>0 and i.Nr_certificat_CM_initial<>'' and i.Nr_certificat_CM_initial=i.Nr_certificat_CM)
			raiserror('Eroare operare: Numar certificat CM initial trebuie sa fie diferit de Numar certificat CM curent!',16,1)

		if exists (select 1 from inserted i where i.Loc_prescriere<>0 and i.Nr_certificat_CM_initial<>'' 
			and not exists (select 1 from infoconmed ic where ic.Data<=i.Data and ic.Marca=i.Marca and ic.Serie_certificat_CM=i.Serie_certificat_CM_initial and ic.Nr_certificat_CM=i.Nr_certificat_CM_initial))
		Begin
			select @mesajeroare='Certificatul medical cu seria '+rtrim(i.Serie_certificat_CM_initial)+' numarul '+rtrim(i.Nr_certificat_CM_initial)+' nu exista ca initial pe aceasta marca!'
			from inserted i
			raiserror(@mesajeroare,16,1)
		End	
	end

	if UPDATE(Cod_urgenta)	--	Verificam consistenta campului Cod urgenta medico-chirurgicala
	begin
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
				where c.Tip_diagnostic='6-' and i.Cod_urgenta='')
			raiserror('Eroare operare: Cod urgenta medico-chirurgicala necompletat!',16,1)
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
				where c.Tip_diagnostic not in ('2-','3-','4-','6-') and i.Cod_urgenta<>'')
			raiserror('Eroare operare: Cod urgenta medico-chirurgicala se completeaza doar pentru codurile de indemnizatie "06 Urgenta medico-chirurgicala","02 Accident in timpul deplasarii la locul de munca","03 Accident de munca","04 Boala profesionala"!',16,1)
	end

	if UPDATE(Cod_boala_grpA)	--	Verificam consistenta campului Cod urgenta medico-chirurgicala
	begin
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
				where c.Tip_diagnostic='5-' and i.Cod_boala_grpA='')
			raiserror('Eroare operare: Cod boala infectocontagioasa grupa A necompletat!',16,1)
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
				where c.Tip_diagnostic='5-' and len(rtrim(i.Cod_boala_grpA))>2)
			raiserror('Eroare operare: Cod boala infectocontagioasa grupa A trebuie sa aiba maxim 2 caractere"!',16,1)
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
				where c.Tip_diagnostic<>'5-' and i.Cod_boala_grpA<>'')
			raiserror('Eroare operare: Cod boala infectocontagioasa grupa A se completeaza doar pentru cod indemnizatie "05 Boala infectocontagioasa din grupa A"!',16,1)
	end

	declare @OperareCMLuniAnt int
	set @OperareCMLuniAnt=dbo.iauParL('PS','OPCMLANT')
	if @OperareCMLuniAnt=0 and UPDATE(Data_inceput) --	Verificam consistenta datei de inceput a concediului medical
	begin
		if exists (select 1 from inserted i where dbo.eom(i.Data_inceput)<>dbo.eom(i.Data))
			raiserror('Eroare operare: Data de inceput trebuie sa fie in luna de lucru!',16,1)
	end 

	if UPDATE(CNP_copil) --Verificam consistenta codului numeric personal al copilului la Ingrijire copil bolnav.
	begin
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
			where c.Tip_diagnostic='9-' and i.Cnp_copil='')
			raiserror('Eroare operare: Cod numeric personal copil necompletat!',16,1)

		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
			where c.Tip_diagnostic='9-' and i.Cnp_copil<>'' and dbo.validare_cnp(i.Cnp_copil)='1' )
			raiserror('Eroare operare: Cod numeric personal copil incorect!',16,1)
	end 

	if UPDATE(Loc_prescriere) --Verificam consistenta locului de prescriere
	begin
		if exists (select 1 from inserted i left outer join conmed c on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput 
			where c.Tip_diagnostic<>'0-' and i.Loc_prescriere=0)
			raiserror('Eroare operare: Loc prescriere necompletat!',16,1)
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidInfoconmed)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
