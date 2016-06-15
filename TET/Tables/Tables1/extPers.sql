CREATE TABLE [dbo].[extPers] (
    [Marca]     CHAR (6) NOT NULL,
    [Fisa_post] IMAGE    NOT NULL,
    [CV]        IMAGE    NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[extPers]([Marca] ASC);

