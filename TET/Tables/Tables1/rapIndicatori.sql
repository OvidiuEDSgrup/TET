CREATE TABLE [dbo].[rapIndicatori] (
    [Cod_indicator]      VARCHAR (20)  NOT NULL,
    [Nume_raport]        VARCHAR (100) NOT NULL,
    [Path_raport]        VARCHAR (500) NULL,
    [Procedura_populare] VARCHAR (50)  NULL,
    CONSTRAINT [PK_CodIndicator_Nume] PRIMARY KEY CLUSTERED ([Cod_indicator] ASC, [Nume_raport] ASC)
);

