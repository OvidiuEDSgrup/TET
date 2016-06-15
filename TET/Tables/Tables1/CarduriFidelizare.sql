CREATE TABLE [dbo].[CarduriFidelizare] (
    [UID]                  VARCHAR (36)  NOT NULL,
    [Tert]                 VARCHAR (13)  NULL,
    [Punct_livrare]        VARCHAR (5)   NULL,
    [Id_Persoana_contact]  VARCHAR (5)   NULL,
    [Mijloc_de_transport]  VARCHAR (30)  NULL,
    [Nume_posesor_card]    VARCHAR (100) NULL,
    [Telefon_posesor_card] VARCHAR (20)  NULL,
    [Email_posesor_card]   VARCHAR (254) NULL,
    [detalii]              XML           NULL,
    [dataora]              DATETIME      DEFAULT (getdate()) NULL,
    [utilizator]           VARCHAR (100) NULL,
    [blocat]               BIT           NULL,
    CONSTRAINT [PK_CarduriFidelizare_UID] PRIMARY KEY CLUSTERED ([UID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Tert]
    ON [dbo].[CarduriFidelizare]([Tert] ASC, [Punct_livrare] ASC, [Id_Persoana_contact] ASC);

