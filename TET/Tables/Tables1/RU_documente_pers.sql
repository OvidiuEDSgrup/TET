CREATE TABLE [dbo].[RU_documente_pers] (
    [ID_Doc]        INT            IDENTITY (1, 1) NOT NULL,
    [Tip]           INT            NULL,
    [Descriere_tip] AS             (case when [Tip]=(1) then 'poza' when [Tip]=(2) then 'cv' else 'Neidentificat' end) PERSISTED NOT NULL,
    [ID_pers]       INT            NULL,
    [Continut]      VARCHAR (2000) NULL,
    CONSTRAINT [PK_RU_documente_pers] PRIMARY KEY CLUSTERED ([ID_Doc] ASC),
    CONSTRAINT [FK_RU_persoane] FOREIGN KEY ([ID_pers]) REFERENCES [dbo].[RU_persoane] ([ID_pers]) ON UPDATE CASCADE
);

