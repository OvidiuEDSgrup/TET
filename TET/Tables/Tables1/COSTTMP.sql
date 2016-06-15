﻿CREATE TABLE [dbo].[COSTTMP] (
    [DATA]        DATETIME     NOT NULL,
    [LM_SUP]      VARCHAR (9)  NOT NULL,
    [COMANDA_SUP] VARCHAR (13) NOT NULL,
    [ART_SUP]     VARCHAR (9)  NOT NULL,
    [LM_INF]      VARCHAR (12) NOT NULL,
    [COMANDA_INF] VARCHAR (13) NOT NULL,
    [ART_INF]     VARCHAR (9)  NOT NULL,
    [CANTITATE]   FLOAT (53)   NOT NULL,
    [VALOARE]     FLOAT (53)   NOT NULL,
    [PARCURS]     INT          NOT NULL,
    [Tip]         VARCHAR (2)  NOT NULL,
    [Numar]       VARCHAR (13) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [princ]
    ON [dbo].[COSTTMP]([DATA] ASC, [LM_SUP] ASC, [COMANDA_SUP] ASC, [ART_SUP] ASC, [LM_INF] ASC, [COMANDA_INF] ASC, [ART_INF] ASC, [CANTITATE] ASC, [VALOARE] ASC, [Tip] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_fisa]
    ON [dbo].[COSTTMP]([ART_INF] ASC, [LM_INF] ASC, [COMANDA_INF] ASC);

