CREATE TABLE [dbo].[docfisc] (
    [Jurnal]     CHAR (3) NOT NULL,
    [Tip_doc]    CHAR (1) NOT NULL,
    [serie]      CHAR (9) NOT NULL,
    [nr_inf]     INT      NOT NULL,
    [nr_sup]     INT      NOT NULL,
    [ultimul_nr] INT      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Agenti]
    ON [dbo].[docfisc]([Jurnal] ASC, [Tip_doc] ASC, [serie] ASC, [nr_inf] ASC);

