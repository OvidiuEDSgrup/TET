CREATE TABLE [dbo].[seriidocrs] (
    [loc_de_munca]    CHAR (9)  NOT NULL,
    [chit_inf]        CHAR (20) NOT NULL,
    [chit_sup]        CHAR (20) NOT NULL,
    [fact_inf]        CHAR (20) NOT NULL,
    [fact_sup]        CHAR (20) NOT NULL,
    [data_eliberarii] DATETIME  NOT NULL,
    [data_consumarii] DATETIME  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [lm_chit_fact]
    ON [dbo].[seriidocrs]([loc_de_munca] ASC, [chit_inf] ASC, [fact_inf] ASC);

