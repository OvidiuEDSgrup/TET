CREATE TABLE [dbo].[SalariiZilieri] (
    [Data]               DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Nr_curent]          SMALLINT   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Comanda]            CHAR (13)  NOT NULL,
    [Ora_inceput]        CHAR (6)   NOT NULL,
    [Ora_sfarsit]        CHAR (6)   NOT NULL,
    [Salar_orar]         FLOAT (53) NOT NULL,
    [Ore_lucrate]        SMALLINT   NOT NULL,
    [Diferenta_salar]    FLOAT (53) NOT NULL,
    [Venit_total]        FLOAT (53) NOT NULL,
    [Impozit]            FLOAT (53) NOT NULL,
    [Rest_de_plata]      FLOAT (53) NOT NULL,
    [Serie_registru]     CHAR (10)  NOT NULL,
    [Nr_registru]        CHAR (10)  NOT NULL,
    [Pagina_registru]    INT        NOT NULL,
    [Nr_curent_registru] INT        NOT NULL,
    [Utilizator]         CHAR (10)  NOT NULL,
    [Data_operarii]      DATETIME   NOT NULL,
    [Ora_operarii]       CHAR (6)   NOT NULL,
    [Explicatii]         CHAR (50)  NOT NULL,
    [Data_platii]        DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[SalariiZilieri]([Data] ASC, [Marca] ASC, [Nr_curent] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Marca]
    ON [dbo].[SalariiZilieri]([Marca] ASC, [Data] ASC, [Nr_curent] ASC);


GO
--***
Create trigger tr_ValidSalariiZilieri on SalariiZilieri for update, insert, delete 
as
Begin
	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'SalariiZilieri' from inserted
	union all
	select DISTINCT Data, 'SalariiZilieri' from deleted
	exec validLunaInchisaSalarii
End	
