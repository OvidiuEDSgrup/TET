CREATE TABLE [dbo].[Potentiali] (
    [idPotential]    INT           IDENTITY (1, 1) NOT NULL,
    [denumire]       VARCHAR (200) NULL,
    [cod_fiscal]     VARCHAR (13)  NULL,
    [cod_localitate] VARCHAR (20)  NULL,
    [note]           VARCHAR (500) NULL,
    [supervizor]     VARCHAR (100) NULL,
    [data_operatii]  DATETIME      DEFAULT (getdate()) NULL,
    [detalii]        XML           NULL,
    PRIMARY KEY CLUSTERED ([idPotential] ASC)
);

