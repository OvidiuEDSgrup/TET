CREATE TABLE [dbo].[ts] (
    [Cont_vechi] CHAR (13) NOT NULL,
    [Cont_IAS]   CHAR (13) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[ts]([Cont_vechi] ASC, [Cont_IAS] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Secundar]
    ON [dbo].[ts]([Cont_IAS] ASC, [Cont_vechi] ASC);

