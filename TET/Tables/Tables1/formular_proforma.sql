CREATE TABLE [dbo].[formular_proforma] (
    [formular]      CHAR (9)  NOT NULL,
    [Numar_pozitie] SMALLINT  NOT NULL,
    [tip]           SMALLINT  NOT NULL,
    [rand]          SMALLINT  NOT NULL,
    [pozitie]       SMALLINT  NOT NULL,
    [expresie]      TEXT      NOT NULL,
    [obiect]        CHAR (20) NOT NULL
);

