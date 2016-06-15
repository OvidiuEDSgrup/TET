CREATE TABLE [dbo].[balanta] (
    [Subunitate]             VARCHAR (9)  NOT NULL,
    [Cont]                   VARCHAR (20) NOT NULL,
    [Denumire_cont]          VARCHAR (80) NOT NULL,
    [Sold_inc_an_debit]      FLOAT (53)   NOT NULL,
    [Sold_inc_an_credit]     FLOAT (53)   NOT NULL,
    [Rul_prec_debit]         FLOAT (53)   NOT NULL,
    [Rul_prec_credit]        FLOAT (53)   NOT NULL,
    [Sold_prec_debit]        FLOAT (53)   NOT NULL,
    [Sold_prec_credit]       FLOAT (53)   NOT NULL,
    [Total_sume_prec_debit]  FLOAT (53)   NOT NULL,
    [Total_sume_prec_credit] FLOAT (53)   NOT NULL,
    [Rul_curent_debit]       FLOAT (53)   NOT NULL,
    [Rul_curent_credit]      FLOAT (53)   NOT NULL,
    [Rul_cum_debit]          FLOAT (53)   NOT NULL,
    [Rul_cum_credit]         FLOAT (53)   NOT NULL,
    [Total_sume_debit]       FLOAT (53)   NOT NULL,
    [Total_sume_credit]      FLOAT (53)   NOT NULL,
    [Sold_cur_debit]         FLOAT (53)   NOT NULL,
    [Sold_cur_credit]        FLOAT (53)   NOT NULL,
    [Cont_corespondent]      VARCHAR (20) NOT NULL,
    [HostID]                 VARCHAR (8)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub_Cont]
    ON [dbo].[balanta]([Subunitate] ASC, [Cont] ASC, [HostID] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_cont_cor]
    ON [dbo].[balanta]([Subunitate] ASC, [Cont_corespondent] ASC, [HostID] ASC);

