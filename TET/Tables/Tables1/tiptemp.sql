CREATE TABLE [dbo].[tiptemp] (
    [terminal] SMALLINT NOT NULL,
    [Tip]      CHAR (2) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tiptemp]([terminal] ASC, [Tip] ASC);

