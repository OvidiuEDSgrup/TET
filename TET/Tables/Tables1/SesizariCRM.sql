CREATE TABLE [dbo].[SesizariCRM] (
    [idSesizare]   INT            IDENTITY (1, 1) NOT NULL,
    [tert]         VARCHAR (200)  NULL,
    [idPotential]  INT            NULL,
    [tip_sesizare] VARCHAR (20)   NULL,
    [descriere]    VARCHAR (500)  NULL,
    [note]         VARCHAR (2000) NULL,
    [supervizor]   VARCHAR (100)  NULL,
    [data]         DATETIME       DEFAULT (getdate()) NULL,
    [stare]        VARCHAR (200)  NULL,
    [detalii]      XML            NULL,
    PRIMARY KEY CLUSTERED ([idSesizare] ASC)
);

