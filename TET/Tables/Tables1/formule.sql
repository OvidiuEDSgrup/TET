CREATE TABLE [dbo].[formule] (
    [Cont_debit]    CHAR (3)  NOT NULL,
    [Cont_credit]   CHAR (3)  NOT NULL,
    [Utilizator]    CHAR (10) NOT NULL,
    [Data_operarii] DATETIME  NOT NULL,
    [Ora_operarii]  CHAR (6)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cd_cc]
    ON [dbo].[formule]([Cont_debit] ASC, [Cont_credit] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Cc_cd]
    ON [dbo].[formule]([Cont_credit] ASC, [Cont_debit] ASC);

