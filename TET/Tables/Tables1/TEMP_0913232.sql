﻿CREATE TABLE [dbo].[TEMP_0913232] (
    [TMPFLD1] CHAR (8)   NOT NULL,
    [TMPFLD2] DATETIME   NOT NULL,
    [TMPFLD3] CHAR (9)   NOT NULL,
    [TMPFLD4] FLOAT (53) NOT NULL,
    [TMPFLD5] CHAR (20)  NOT NULL,
    [TMPFLD6] CHAR (80)  NOT NULL,
    [TMPFLD7] DATETIME   NOT NULL,
    [TMPFLD8] CHAR (8)   NOT NULL,
    [TMPFLD9] CHAR (20)  NOT NULL,
    [TS]      ROWVERSION NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KEY_TSTEMP_0913232]
    ON [dbo].[TEMP_0913232]([TS] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [KEY001TEMP_0913232]
    ON [dbo].[TEMP_0913232]([TMPFLD7] DESC, [TMPFLD8] DESC, [TMPFLD9] DESC, [TS] ASC);
