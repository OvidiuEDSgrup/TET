CREATE TABLE [dbo].[tmp_indicatori] (
    [Cod_Indicator]      CHAR (20)      NOT NULL,
    [Denumire_Indicator] CHAR (60)      NOT NULL,
    [Expresia]           VARCHAR (3000) NOT NULL,
    [Unitate_de_masura]  CHAR (1)       NOT NULL,
    [Expresie]           BIT            NOT NULL,
    [Descriere_expresie] CHAR (3000)    NOT NULL,
    [Total]              BIT            NOT NULL,
    [Modificat]          BIT            NOT NULL,
    [Ordine_in_raport]   SMALLINT       NOT NULL
);

