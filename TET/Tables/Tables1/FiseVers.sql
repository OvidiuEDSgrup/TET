CREATE TABLE [dbo].[FiseVers] (
    [An]       SMALLINT NOT NULL,
    [Varianta] SMALLINT NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[FiseVers]([An] ASC, [Varianta] ASC);

