﻿CREATE TABLE [dbo].[TEMP_9893800] (
    [TMPFLD1]  CHAR (9)   NOT NULL,
    [TMPFLD2]  CHAR (20)  NOT NULL,
    [TMPFLD3]  CHAR (13)  NOT NULL,
    [TMPFLD4]  DATETIME   NOT NULL,
    [TMPFLD5]  CHAR (20)  NOT NULL,
    [TMPFLD6]  FLOAT (53) NOT NULL,
    [TMPFLD7]  FLOAT (53) NOT NULL,
    [TMPFLD8]  FLOAT (53) NOT NULL,
    [TMPFLD9]  CHAR (1)   NOT NULL,
    [TMPFLD10] CHAR (2)   NOT NULL,
    [TMPFLD11] CHAR (13)  NOT NULL,
    [TMPFLD12] CHAR (13)  NOT NULL,
    [TMPFLD13] DATETIME   NULL,
    [TS]       ROWVERSION NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KEY_TSTEMP_9893800]
    ON [dbo].[TEMP_9893800]([TS] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [KEY001TEMP_9893800]
    ON [dbo].[TEMP_9893800]([TMPFLD13] DESC, [TS] ASC);

