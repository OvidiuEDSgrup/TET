CREATE TABLE [dbo].[Infopontaj] (
    [Data]         DATETIME NOT NULL,
    [Marca]        CHAR (6) NOT NULL,
    [Numar_curent] SMALLINT NOT NULL,
    [Loc_de_munca] CHAR (9) NOT NULL,
    [Tip]          CHAR (1) NOT NULL,
    [Data_inceput] DATETIME NOT NULL,
    [Data_sfarsit] DATETIME NOT NULL,
    [Tura]         CHAR (1) NOT NULL,
    [Ora_inceput]  CHAR (6) NOT NULL,
    [Ora_sfarsit]  CHAR (6) NOT NULL,
    [detalii]      XML      NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[Infopontaj]([Data] ASC, [Marca] ASC, [Tip] ASC, [Data_inceput] ASC, [Ora_inceput] ASC);


GO
--***
create trigger tr_ValidInfoPontaj on infopontaj for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	declare @userASiS varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)

	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'INFOPONTAJ' from inserted
	union all
	select DISTINCT Data, 'INFOPONTAJ' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca) 
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED where Loc_de_munca=''
		exec validMarcaSalarii
	end 

	/* Validare loc de munca */
	if UPDATE(Loc_de_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @userASiS,loc_de_munca,data from inserted where Marca=''
		exec validLMSalarii
	end 

end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidInfoPontaj)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
