[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)  [![Gitter](https://img.shields.io/gitter/room/saspy-bffs/community.svg?color=777777)](https://gitter.im/saspy-bffs/community)


# Friends are better with Everything: Using PROC FCMP Python Objects in Base SAS


### Materials from a 50-minute Invited Presentation at [Western Users of SAS Software](https://www.wuss.org) in San Francisco, California, on September 15, 2022.

Materials provided:

- [Full conference paper](paper/Paper-PROC_FCMP_Python-WUSS2022.pdf)

- [Full conference paper examples as a .sas file](examples/Examples-PROC_FCMP_Python-WUSS2022.sas), with several example use cases for embedding Python code inside of SAS programs

- [Slides](slides/Slides-PROC_FCMP_Python-WUSS2022.pdf)

If you're interested in the opposite direction (embedding SAS code inside of Python), see [https://github.com/saspy-bffs/wuss-2022-class](https://github.com/saspy-bffs/wuss-2022-class)


## Prerequisites

The .sas example file requires SAS 9.4M6 or newer, along with an installation of Python 2.7 or higher in the same environment. In addition, as explained on page 3 of the [paper](paper/Paper-PROC_FCMP_Python-WUSS2022.pdf), environment variables `MAS_M2PATH` and `MAS_PYPATH` need to be set to allow SAS to talk with Python.

Some of the examples also rely on specific Python packages being installed, as explained on pages 2-3 of the [paper](paper/Paper-PROC_FCMP_Python-WUSS2022.pdf).


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.


## Authors

* [ilankham](https://github.com/ilankham)
* [mtslaugh](https://github.com/mtslaugh)


## Disclaimer

This project is in no way affiliated with SAS Institute Inc.
