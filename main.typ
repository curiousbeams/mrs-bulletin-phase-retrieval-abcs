#import "@preview/pubmatter:0.2.2"
#import "@preview/lovelace:0.3.0": pseudocode-list
#import "@preview/equate:0.3.2": equate
// #import "@preview/wordometer:0.1.5": word-count, total-words

#let fm = pubmatter.load(
  (
    authors: (
        (
        name: "Georgios Varnavides",
        email: "g.varnavides@tudelft.nl",
        orcid: "0000-0001-8338-3323",
        affiliations: "Department of Imaging Physics, Delft University of Technology",
      ),
      (
        name: "Willem P.M. de Kleijne",
        affiliations: "Department of Imaging Physics, Delft University of Technology",
        orcid: "0009-0009-9635-8763"
      ),
      (
        name: "Stephanie M. Ribet",
        email: "sribet@lbl.gov",
        orcid: "0000-0002-7117-066X",
        affiliations: "National Center for Electron Microscopy, Molecular Foundry, Lawrence Berkeley National Laboratory",
      ),
  ),
    date: datetime.today(),
    title: [
      The ABCs of Phase Retrieval
    ],
    subtitle: [
      Connecting the Acronyms of Scanning Transmission Electron Microscopy
    ],
    abstract: [
      High-resolution scanning transmission electron microscopy (STEM) is an indispensable tool for characterizing the structure and properties of materials down to the atomic scale.
      Conventional STEM imaging, however, is limited by the phase problem, whereby the phase of the electron exit wave is lost upon detection.
      Recent advances in diffractive imaging and 4D-STEM have enabled a range of phase retrieval techniques that computationally reconstruct the missing information.
      These approaches offer improved dose efficiency and enhanced  sensitivity to weakly scattering signals, extending quantitative imaging to beam-sensitive materials composed of light elements.
      In this work, we introduce the phase problem in electron microscopy and survey the diverse landscape of phase retrieval techniques used in the field.
      Despite their many acronyms and algorithmic variations, these techniques share a common physical and mathematical foundation.
      We present a unified framework that connects these seemingly distinct methods, from parallax imaging and tilt-corrected bright field (tcBF-STEM), to aberration-corrected bright-field (acBF-STEM), optimum bright field (OBF-STEM) and single-sideband (SSB) ptychography, as well as iterative ptychographic algorithms.
      Based on these insights, we discuss the opportunities and practical limitations of applying these methods across different materials systems, detector designs, and microscope configurations.
    ],
    keywords: (
      "electron microscopy",
      "phase contrast",
      "phase retrieval",
      "parallax",
      "center-of-mass",
      "ptychography"
    )
  ),
)

// MyST Theme
#let mrs-col = rgb("#3e2276ff")
#let theme = (color: mrs-col, font: "Noto Sans")
#state("THEME").update(theme)

#set page(
  header: pubmatter.show-page-header(fm), 
  footer: pubmatter.show-page-footer(fm),
  columns: 2
)
#show cite: it => text(fill: mrs-col, it)
#show ref: it => text(fill: mrs-col, it)

#set text(font: "Noto Serif", size: 9pt)
#set par(justify: true)
#show heading: set text(mrs-col)   

#show: equate.with(sub-numbering: true,number-mode:"label")
#set math.equation(numbering: "(1.1)", supplement: "Eq. ")

// #let no-number-eq = math.equation.with(block: true, numbering: none)

#show figure: align.with(center)
#show figure: set text(8pt)
#show figure.caption: align.with(left)

#show ref: it => {
  if it.element != none and it.element.numbering == none {
    link(
      it.target,
      text(mrs-col)[#it.element.supplement #it.element.body]
    )
  } else {
    it
  }
}

// #show: word-count
#let diaer = "\u{308}"

#place(
  top + left,
  float: true,
  scope: "parent",
  [
  #pubmatter.show-title-block(fm)
  #pubmatter.show-abstract-block(fm)
]
)

= Introduction

Scanning transmission electron microscopy (S/TEM) enables the characterization of specimens from the micron scale down to the atomic scale, making it an indispensable characterization tool for any materials scientist @Williams_2009.
S/TEM instruments operate in two complimentary acquisition modalities: _imaging mode_, which produces a magnified real-space image of the specimen, and _diffraction mode_, which records the angular distribution of scattered electrons in reciprocal space @Carter_2016.

Traditional parallel-illumination TEM imaging is widely used across disciplines, from high-resolution studies of frozen-hydrated biomolecules @Vinothkumar_2016 to lattice-resolved @Alcorn_2023 and defect@Fultz_2013 imaging of materials.
In contrast, STEM employs a highly converged electron probe containing a broad range of incident wavevectors. 
When this probe interacts with the specimen, it produces a diffraction pattern that encodes the local scattering. 
In this sense, STEM is inherently a diffraction-mode technique, although real-space images can be obtained by processing the resulting position-resolved diffraction patterns -- a process we will refer to as _diffractive imaging_.
This approach routinely provides interpretable, atomic-resolution imaging of crystalline materials and forms the basis of modern materials characterization @Ophus_2023.

Both modalities are fundamentally limited by the microscopy "phase problem," which suppresses contrast from weakly scattering specimens and limits quantitative interpretation.
In this review, we focus on the mathematical foundations of STEM phase-retrieval techniques, which reconstruct the missing phase and thereby overcome these intrinsic contrast limitations.
We emphasize the implications of these methods for quantitative materials characterization and set the stage for a unified treatment of the underlying physics.

#figure(
  image("vector/schematic.pdf",width: 100%),
  caption: [
    Microscope configurations.
    *a)* TEM Zernike phase-contrast imaging, 
    *b)* small convergence angle 4D-STEM, used for "nanobeam" experiments, 
    and *c)* large convergence angle 4D-STEM, used for diffractive imaging experiments.
  ],
  placement: top,
  scope: "parent"
) <fig-schematic>

== Microscopy Phase Problem

The phase problem arises in electron microscopy because the scattered electron wavefunction -- the "exit wave" -- is complex-valued, yet physical detectors only measure real-valued intensities @Fienup_1982.
In other words, although the specimen primarily imprints a _phase shift_ on the complex incident electron wavefunction $psi$, the detector records $abs(psi)^2$, seemingly discarding the information that carries most of the specimen's structure.

For S/TEM, this becomes clear in the wave propagation formalism.
The evolution of an electron wavefunction, $psi(bold(r))$, along the optical axis $z$ is governed by the Schro#diaer;dinger equation for fast electrons @Kirkland_2020:

$
  (partial psi(bold(r))) / (partial z) = (upright(i) lambda)/(4 pi) nabla_(x y)^2 psi(bold(r)) + upright(i) sigma V(bold(r)) psi(bold(r)),
$ <eq-shrodinger>
where $lambda$ is the relativistic wavelength, $sigma$ the interaction constant, $nabla_(x y)^2$ the in-plane Laplacian operator, and $V(bold(r))$ the specimen electrostatic potential.

The two terms on the right-hand side of @eq-shrodinger are the propagation and transmission operators.
Because these operators do not commute, numerical solutions typically use a split-step algorithm known as the multislice method @Cowley_1957:
The specimen is partitioned into $n$ thin slices, and the wavefunction is updated by alternating between transmission through each slice and free-space propagation @Kirkland_2020:
$
  psi_(n+1)(bold(r)) & = exp[(upright(i) lambda Delta z)/(4 pi) nabla_(x y)^2]exp[upright(i) sigma V_n^(Delta z)(bold(r))] psi_n(bold(r)), #h(2em) #label("eq-ms") \
  V_n^(Delta z)(bold(r)) &= integral_(z_n)^(z_n + Delta z) V(bold(r)) d z. #label("eq-projected-pot")
$<eq-ms-both>
Inspecting @eq-ms-both shows that the specimen information enters solely through a multiplicative phase factor $exp[upright(i) sigma V_n^(Delta z)(bold(r))]$.
Electrons are not  absorbed by the specimen (ignoring weak inelastic losses) and any apparent amplitude modulation simply reflects electrons scattered outside the acceptance angle of the detector.
Thus, the structural information of interest to materials scientists is encoded in the phase of the exit wave, not its magnitude. 
Recovering the exit wave phase from intensity-only measurements is therefore the central challenge.

== Phase Contrast Imaging

A direct approach to the microscopy phase problem is to leverage the imaging optics to convert otherwise imperceptible phase variations in the exit wave into measurable intensity variations in the imaging plane.
This approach, known as _phase contrast imaging_ (PCI) @Carter_2016, is most naturally implemented in planewave TEM, where the objective lens forms a magnified real-space image of the specimen.

To illustrate the basic principle, we restrict our attention to weakly-scattering specimens satisfying the _weak phase object approximation_ (WPOA), for which the exit wave can be written as @Vulovic_2014:
$
  psi_text("exit")(bold(r)) approx 1 + upright(i) sigma V_p (bold(r)) + cal(O)(sigma^2 V_p^2(bold(r))),
$ <eq-wpoa>
where $V_p (bold(r)) = integral_(-infinity)^infinity V(bold(r)) d z$ is the projected potential and we drop terms quadratic in the interaction constant.
In this regime the specimen modifies only the phase of the electron wavefunction, so additional optical manipulations are required to convert the phase into measurable amplitude contrast.

=== Defocus Phase Contrast

The simplest such manipulation is intentional over- or under-focus of the objective lens.
Defocus by a value $Delta f$ multiplies the exit wave in reciprocal space by a quadratic phase factor given by,
$
  tilde(psi)'(bold(q)) = exp[-upright(i) pi lambda Delta f abs(bold(q))^2] tilde(psi)(bold(q)).
$ <eq-defocus>
Transforming this to real-space and expanding to first order in $sigma V_p (bold(r))$, the image intensity becomes:
$
  I(bold(r)) approx 1 - 2 sigma [V_p (bold(r)) convolve.o h_(Delta f)(bold(r))],
$<eq-defocus-int>
where $h_(Delta f)(bold(r)) = cal(F)^(-1)_(bold(q) arrow bold(r)) {sin[pi lambda Delta f abs(bold(q))^2]}$ is the real-space convolution kernel corresponding to @eq-defocus and $convolve.o$ represents the convolution operation.
Defocus thus converts sample-induced phase variations into intensity contrast through a sinusoidal convolution, leading to characteristic contrast reversals with increasing spatial frequency.

=== Phase Plate Contrast

Another approach is to introduce a phase shift using a post-specimen phase plate (@fig-schematic\a).
Originating from optical phase contrast microscopy, it was awarded the 1953 Physics Nobel prize for transformative impact on biological imaging @Zernike_1942.
An ideal phase plate shifts the unscattered beam by $pi\/2$:

$
  tilde(psi)'(bold(q)) = cases(
    upright(i) tilde(psi)(bold(q)) &"if" bold(q) = bold(0),
    tilde(psi)(bold(q)) &"otherwise."
  )
$ <eq-zernike>
Expanding again to first order in $sigma V_p (bold(r))$, the corresponding image intensity is given by:
$
  I(bold(r)) approx 1 + 2 sigma V_p (bold(r)),
$<eq-zernike-int>
showing that a phase plate enables direct, linear transfer of the specimen phase into image intensity.

@fig-pci illustrates these effects for a simulated 3D arrangement of single- and double-walled carbon nanotubes (CNTs) acquired at low dose. 
The in-focus HRTEM image shows almost no contrast, especially for the top nanotube which is at exactly the focal plane of the microscope.
Defocus improves visibility but introduces frequency-dependent contrast reversals, causing different regions of the CNTs to appear in or out of focus.
Zernike phase contrast recovers both the high-resolution lattice information and the low-frequency envelope distinguishing the CNTs from vacuum.

#figure(
  image("raster/phase_contrast_imaging_CNTs.png",width: 100%),
  caption: [
    Simulated high-resolution TEM imaging *a)* of single- and double-walled carbon nanotubes, acquired with an electron dose of 500 e/\u{00C5}#super[2]  using:
    *b)* in-focus optics, *c)* 50 nm of over-focus, and *d)* an ideal Zernike phase plate.

  ],
  placement: top,
  scope: "parent"
) <fig-pci>

== Diffractive Imaging

As discussed above, STEM is inherently a diffraction-based technique: at each probe position $bold(R)$, we have access to the diffraction intensity $I(bold(R),bold(k)) = abs(tilde(psi)_text("exit")(bold(R),bold(k)))^2$, where $bold(k)$ is the in-plane scattering vector.
Historically, STEM has used monolithic annular detectors that integrate this intensity within annular collection limits to form a real-space image.
A conventional annular signal is therefore given by:
$
  I_text("ann")(bold(R)) = integral_(theta_text("in"))^(theta_text("out")) I(bold(R),bold(k)) d bold(k),
$<eq-annular-int>
yielding familiar contrast modes such as bright-field (BF), annular bright-field (ABF), annular dark-field (ADF), and high-angle annular dark-field (HAADF) STEM @Crewe_1970 @Pennycook_1991.
Dark field images in particular are highly interpretable -- especially for crystalline specimens -- leading to their prevalence in materials science characterization @Ophus_2023. 
However, they discard sensitive information encoded in the exit-wave phase and are often not sufficiently electron dose-efficient for beam-sensitive samples.

The development of fast, low-noise direct-electron detectors@Levin_2021 has enabled recording the full diffraction pattern $I(bold(R),bold(k))$ at every scan position, giving rise to a family of techniques collectively known as 4D-STEM @Ophus_2019.
These datasets retain the full diffractive signature of the probe–specimen interaction, far beyond what can be accessed with scalar annular signals.
Small convergence angle ("nanobeam") and large convergence angle (diffractive imaging) geometries are shown in @fig-schematic\b-c respectively.
In this review, we will focus on the large set of approaches that computationally recover the phase of the specimen from this set of diffraction patterns, and this largely relies on a large convergence alignment (@fig-schematic\c).
We  refer to this class of approaches as diffractive imaging or STEM _phase retrieval_ techniques @sanchez2025.

=== Weak Phase Object Approximation

Under the WPOA in @eq-wpoa, the specimen transmission function is $t(bold(r)) approx 1 + upright(i) sigma V_p (bold(r))$, with the Fourier transform of the scattered component given by $tilde(phi)(bold(k)) = cal(F)_(bold(r) arrow bold(k)){sigma V_p (bold(r))}$.
In this regime, the diffraction intensity can be written as the self-convolution of the converged probe $tilde(psi)(bold(k))$ with the WPOA term @Rodenburg_1993:
$
  I(bold(R),bold(k)) = integral integral &tilde(psi)(bold(k')) tilde(phi)(bold(k-k')) tilde(psi)^*(bold(k''))tilde(phi)^*(bold(k-k'')) \ &exp[2 pi upright(i) bold(R) dot (bold(k'-k''))] d bold(k') d bold(k'')
$ <equate:revoke>

Following #cite(<Rodenburg_1993>,form: "author"), it is convenient to take the Fourier transform of the measured intensities with respect to the scan position: $G(bold(q),bold(k)) = cal(F)_(bold(R) arrow bold(q)){I(bold(R),bold(k))}$, where $q$ represents the Fourier transform of the real space vector $r$.
Using $tilde(phi)(bold(k)) = - tilde(phi)^*(-bold(k))$ @Rodenburg_1993, one obtains the compact form @Yang_2016:
$
  G(bold(q),bold(k)) &= abs(tilde(psi)(bold(k)))^2 delta(bold(q)) + Gamma(bold(q),bold(k)) tilde(phi)(bold(q)) \
  Gamma(bold(q),bold(k)) &equiv tilde(psi)^*(bold(k))tilde(psi)(bold(k-q)) - tilde(psi)(bold(k))tilde(psi)^*(bold(k+q)),
$<eq-wpoa-forward>
where the aperture overlap function $Gamma(bold(q),bold(k))$ encapsulates the probe geometry and forms the basis of all direct STEM phase retrieval methods.
@fig-gamma shows characteristic views of $Gamma(bold(q),bold(k))$ for a defocused converged probe with a circular aperture.

We take the probe to have the form $tilde(psi)(bold(k)) = A(bold(k)) upright(e)^(-upright(i) chi(bold(k)))$, where
$A(bold(k))$ is a top-hat function describing the probe-forming aperture and $chi(bold(k))$ is the aberration surface given by:
$
chi(bold(k)) = (2 pi) / lambda sum_(n,m) 1 / (n+1) C_(n,m) (k lambda)^(n+1) cos[m(theta - theta_(n,m))] #h(1.5em)
$<eq-chi>

where $k = abs(bold(k))$, $theta = arctan[bold(k)]$, $n$ and $m$ are radial and azimuthal orders of coefficients $C_(n,m)$ with  axis $theta_(n,m)$.

#figure(
  image("raster/mrs-bulletin-fig2.png",width: 100%),
  caption: [
    Components of the aperture overlap function, $Gamma(bold(q),bold(k))$.
    *a)* Probe forming aperture with (bottom) and without (top) aberration function at the back focal plane. 
    *b)* Slicing along spatial frequencies $bold(q)$ and plotting over the detector frequencies $bold(k)$, highlights the so-called "double" and "triple" overlap "trotter" regions.
    *c)* Slicing along detector frequencies $bold(k)$ and plotting over the spatial frequencies $bold(q)$, illustrates the effect of shifting the probe aperture and aberrations.
  ],
  placement: top,
  scope: "parent"
) <fig-gamma>

=== Transfer of Information

Under the WPOA, STEM image formation is linear in the specimen phase.
This allows us to define a contrast transfer function, $text("CTF")(bold(q))$,describing how well spatial frequencies of the specimen are transmitted or, in the context of STEM phase retrieval techniques, how faithfully they can be reconstructed.
We write the reconstructed phase as:
$
  tilde(psi)_text("rec")(bold(q)) &= 2 tilde(phi)(bold(q)) times text("CTF")(bold(q)),
$<eq-recon-ctf>
where the factor of 2 follows common conventions @Dwyer_2024 @Vega_2025.
An ideal phase retrieval method would therefore satisfy $text("CTF")_text("ideal")(bold(q)) =1$.
For an arbitrary detector response function $D_j (bold(k))$ (with $j$ indexing a detector pixel or segment), #cite(<Hammel_1995>,form: "author") showed that the complex-valued CTF is @Hammel_1995 @rose_1977
$
  text("CTF")_j (bold(q)) = i /2 integral &D_j (bold(k)) tilde(psi)^*(bold(k)) tilde(psi)(bold(q-k)) #label("equate:revoke") \
  - &D_j (bold(k)) tilde(psi)(bold(k)) tilde(psi)^*(bold(q+k)) d bold(k). 
$ <eq-ctf>

For a pixelated detector, $D_j (bold(k)) = delta(bold(k))$, so the integrand reduces to the aperture-overlap function $Gamma(bold(q),bold(k))$.
More compact expressions follow from an asymmetric decomposition of cross-correlations @Bekkevold_2025 @Lazic_2017
#[
#show math.equation.where(block: true): set align(left)
$
  Re{text("CTF")_j (bold(q))} &= 1/2 {[psi star psi D_j](bold(q)) + [psi D_j star psi](bold(q))} #label("eq-ctf-corr-real")\
  Im{text("CTF")_j (bold(q))} &= 1/2 {[psi star psi D_j](bold(q)) - [psi D_j star psi](bold(q))}, #label("eq-ctf-corr-imag")
$ <eq-ctf-corr>
]
where $star$ denotes cross-correlation and $Re{dot}$ and $Im{dot}$ represent real and imaginary components.

Two limiting cases of @eq-ctf provide further physical insight.
In the absence of aberrations, $chi(bold(k))=0$, the real-part of @eq-ctf-corr vanishes and the imaginary part reduces to the aperture auto-correlation:
$
  text("CTF")_text("in-focus")(bold(q)) &= upright(i) [A star A](bold(q)) \
  &= upright(i) thin Re[cal(F)^(-1)_(bold(r)arrow bold(q)){abs(cal(F)_(bold(q)->bold(r)){A(bold(q))})^2}]. #label("equate:revoke")
$<eq-infocus-ctf>
This envelope is a fundamental limit for all direct STEM phase retrieval methods.
Similarly, evaluating @eq-ctf for the axial illumination case, $bold(k)=0$, yields a purely imaginary CTF:
$
  text("CTF")_text("axial")(bold(q)) = -upright(i) sin[chi(bold(q))],
$<eq-ctf-axial>
which is precisely the HRTEM CTF derived in the previous section, illustrating the _principle of reciprocity_ between TEM and STEM techniques @Williams_2009 @Carter_2016 @Kirkland_2020.

=== Statistically Reliable Information

The CTF only describes the maximum transferable signal, not the statistical reliability of that signal under noise.
A complete description of information transfer must account for noise statistics, notably shot noise in electron detectors.
The natural figure of merit is the spectral signal-to-noise ratio @Unser_1987 @Varnavides_2025_ssnr,
$
  text("SSNR")(bold(q)) = (abs(chevron.l tilde(psi)(bold(q)) chevron.r))/sqrt(op("Var")[tilde(psi)(bold(q))]),
$<eq-ssnr>
which quantifies the statistically reliable recoverable information at each spatial frequency.
The SSNR is related to the detective quantum efficiency (DQE), recently introduced as a quantitative performance metric for STEM phase retrieval @Bennemann_2025:
$
  text("DQE")(bold(q)) = (text("SSNR")_text("out")^2 (bold(q))) / (text("SSNR")_text("in")^2 (bold(q)) ),
$ <eq-dqe>
where $text("SSNR")_text("in")(bold(q))$ is the SSNR of an "ideal" reference system, typically taken as HRTEM with a Zernike phase plate @Zernike_1942 @Vega_2025.
Thus, the DQE provides a normalized measure of how efficiently a method transfers information relative to a theoretical optimum.

= Direct Phase Retrieval Techniques

Equipped with the WPOA aperture-overlap and CTF/SSNR formalisms, we are now ready to investigate the zoo of direct STEM phase retrieval methods and their various acronyms.
These differ primarily in how they combine the Fourier-transformed measured diffraction intensities $G(bold(q),bold(k))$ to produce an estimate for the specimen phase $tilde(phi)(bold(q))$.

== Phase-Compensated Coherent Sum <sec-ssb>

The first technique we will investigate goes by two seemingly unrelated names: _aberration-corrected bright-field (acBF) STEM_ @Ma_2025 and _phase-compensated single-sideband (SSB) ptychography_ @Yang_2016.
The former highlights its close connection to _tilt-corrected bright-field (tcBF) STEM_, which we investigate further in @sec-parallax.
The latter name reflects the structure of the WPOA forward model in @eq-wpoa-forward, which contains two redundant contributions at $bold(q)$ and $-bold(q)$.

In the absence of aberrations, these two "sidebands" are related by complex conjugation according to Friedel's law @Friedel_1913, so the specimen phase $tilde(phi)(bold(q))$ can be reconstructed using only one of them.
In practice, once aberrations are present, the two sidebands are no longer perfect conjugates: residual aberrations imprint an additional geometric phase to the aperture-overlap function $Gamma(bold(q),bold(k))$.

The key insight behind SSB is that, under the WPOA, detector pixels sampling the same sideband carry the same specimen phase $tilde(phi)(bold(q))$.
Differences between pixels arise only from known, instrument-dependent phases, namely aberration-induced geometric phases and aperture-overlap geometry.
If these extra phases are removed, sideband contributions from all detector pixels can be added coherently.

Phase-compensated SSB accomplishes this by dividing $Gamma(bold(q),bold(k))$ by its magnitude and retaining only its phase factor, effectively rotating each detector-plane frequency into a common phase reference.
The estimated phase is then obtained by coherently summing all phase-aligned detector samples @Yang_2016:
$
  tilde(phi)_text("SSB")(bold(q)) = sum_bold(k) (Gamma^*(bold(q),bold(k)) G(bold(q), bold(k)))/(abs(Gamma(bold(q),bold(k)))).
$<eq-ssb-recon>

@eq-ssb-recon works remarkably well and remains one of the most widely used direct phase retrieval techniques.
Inserting the forward model $G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q))$ into @eq-ssb-recon gives the SSB CTF @Yang_2016:
$
  text("CTF")_text("SSB")(bold(q)) = upright(i)/2 sum_bold(k) abs(Gamma(bold(q),bold(k))).
$<eq-ctf-ssb>
For spatial frequencies beyond the aperture semiangle $abs(bold(q)) > q_0$, the overlap $Gamma(bold(q),bold(k))$ reduces to the "double-overlap" region, and the CTF collapses to the ideal autocorrelation enveloped in @eq-infocus-ctf.

To understand the SSB variance, note that each detector frequency contributes a noisy measurement:
$
  G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q)) + n(bold(q),bold(k)), 
$ <eq-noise-model>
with unit-variance noise $n(bold(q),bold(k))$ @Bennemann_2025.
The phase-alignment step preserves unit variance, so noise contributions add incoherently, while the signal adds coherently.
Thus, the total variance at each spatial frequency $bold(q)$ is simply the number of detector pixels for which $Gamma(bold(q),bold(k))$ is nonzero: 
$
op("Var"[tilde(phi)_text("SSB")(bold(q))]) &= sum_bold(k) 1_(\{abs(Gamma(bold(q),bold(k))) >0\})  #label("equate:revoke")\
& = 2 D(bold(q)) + T(bold(q)),
$<eq-var-ssb>
where $D(bold(q))$ and $T(bold(q))$ are the double and triple overlap regions (@fig-gamma).
The resulting SSNR is @Bennemann_2025 @Varnavides_2025_ssnr:
$
  text("SSNR")_text("SSB")(bold(q)) = (sum_bold(k) abs(Gamma(bold(q),bold(k)))) / (2 sqrt(2 D(bold(q)) + T(bold(q))))
$<eq-ssb-ssnr>

== Noise-Flattening Normalization <sec-obf>

Phase-compensated SSB improves robustness against residual aberrations by removing the geometric phase of the aperture-overlap function before summing detector-plane frequencies.
However, SSB still treats all contributing detector pixels equally, even though the strength of the aperture overlap varies strongly across the BF disk, resulting in a statistically sub-optimal reconstruction.

The _optimum bright-field (OBF) STEM_ method addresses this by applying a noise-matched normalization to the SSB estimator @Ooe_2021 @Ooe_2024.
Starting from the phase-aligned numerator, OBF introduces a scalar normalization factor proportional to the root-mean-squared aperture overlap strength to obtain:
$
  tilde(phi)_text("OBF")(bold(q)) =  (sum_bold(k)Gamma^*(bold(q),bold(k)) G(bold(q), bold(k)))/sqrt(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2).
$<eq-obf-recon>

The denominator rescales the coherent SSB sum by the effective SSNR of the bright-field detector region.
For each spatial frequency, this normalization prevents a small subset of bright-field pixels with weak overlap from amplifying noise.
Thus, OBF can be viewed as a noise-flattened SSB formulation, retaining geometric phase compensation but adjusting its gain to reflect information reliability.

Substituting $G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q))$ into @eq-obf-recon gives:
$
  text("CTF")_text("OBF")(bold(q)) = upright(i)/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$<eq-obf-ctf>

Using the additive unit-variance noise model from @eq-noise-model, the OBF estimator numerator becomes:
$
  sum_bold(k) Gamma^*(bold(q),bold(k)) G(bold(q),bold(k)) = &sum_bold(k) abs(Gamma(bold(q),bold(k)))^2 tilde(phi)(bold(q)) + \ &sum_bold(k) Gamma^*(bold(q),bold(k)) n(bold(q),bold(k)), #label("eq-obf-numerator")
$
with the second term describing the additive noise contributions with total variance:
$
  op("Var")[sum_bold(k) Gamma^*(bold(q),bold(k)) n (bold(q),bold(k))] = sum_bold(k) abs(Gamma(bold(q),bold(k)))^2.
$<eq-obf-var>
This is precisely the OBF denominator squared, thus normalizing the OBF variance to unity, $op("Var")[tilde(phi)_text("OBF")(bold(q))]=1$.
The resulting OBF SSNR is given by the magnitude of its CTF:
$
  text("SSNR")_text("OBF")(bold(q)) = 1/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$<eq-obf-ssnr>

#figure(
  // image("raster/direct-ctf-figure.png"),
  image("vector/direct-ctf-figure.svg",width: 100%),
  placement: top,
  scope: "parent",
  caption: [
    Contrast transfer functions (CTFs) and spectral signal-to-noise (SSNRs) for all direct techniques investigated across different acquisition parameters, highlighting the SSNR equivalence for SSB, OBF, and MF/WDD. 
  ]
) <fig-ctf>

== Least-Squares Matched-Filter <sec-wdd>

The OBF estimator above improves SSB by normalizing the coherent sum, but it is not formally a least-squares estimator.
The proper matched-filter (MF) solution for recovering $tilde(phi)(bold(q))$ from the WPOA forward model is obtained by minimizing $sum_bold(k) abs(G(bold(q),bold(k)) - Gamma(bold(q),bold(k))tilde(phi)(bold(q)))^2$, yielding the estimator:
$
  tilde(phi)_text("MF")(bold(q)) =  (sum_bold(k)Gamma^*(bold(q),bold(k)) G(bold(q), bold(k)))/(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2 + epsilon(bold(q))).
$<eq-mf-recon>

While @eq-mf-recon is simple, direct evaluation in detector-space is numerically unstable:
the numerator contains highly oscillatory phases from $Gamma(bold(q),bold(k))$, and the denominator depends on the squared magnitude of a rapidly varying overlap kernel.
Applying Parseval's theorem, $sum_k abs(tilde(f)(k))^2 = integral d r abs(f(r))^2$, and inverse Fourier transforming over $bold(k)$ gives the MF estimator in the mixed-domain representation:
$
  tilde(phi)_text("MF-mix")(bold(q)) &= (integral W^*(bold(q),bold(rho)) H(bold(q),bold(rho)) d bold(rho))/(integral abs(W(bold(q),bold(rho)))^2 d bold(rho) + epsilon(bold(q))) #label("eq-mf-mixed-recon") \ 
  W(bold(q),bold(rho)) &= cal(F)^(-1){Gamma(bold(q),bold(k))} #label("eq-wigner-w") \
  H(bold(q),bold(rho)) &= cal(F)^(-1){G(bold(q),bold(k))} #label("eq-wigner-h")
$
where $bold(rho)$ is the detector separation.
This utilizes the fact that the kernel $W(bold(q),bold(rho))$ is highly-localized in $rho$, suggesting that we can further improve numerical stability by switching to a pixelwise normalization:
$
  tilde(phi)_text("WDD")(bold(q)) = integral (W^*(bold(q),bold(rho)) H(bold(q),bold(rho)))/(abs(W(bold(q),bold(rho)))^2  + epsilon(bold(q),bold(rho))) d bold(rho),
$<eq-wdd-recon>
which is commonly referred to as the _Wigner distribution deconvolution (WDD)_ method @Rodenburg_1992 @Li_2014 @Yang_2017.
Similar to SSB, usually only one of the sidebands is used to form the kernel $W(bold(q),bold(rho)) = cal(F)^(-1){tilde(psi)(bold(k-q))tilde(psi)^*(bold(k)))}$.

The MF (and equivalently WDD) estimator can be characterized by a contrast transfer function by inserting the forward model into @eq-mf-recon:
$
  text("CTF")_text("MF")(bold(q)) =  (sum_bold(k) abs(Gamma(bold(q),bold(k)))^2 )/(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2 + epsilon(bold(q))).
$<eq-mf-ctf>
Note that for sufficiently small regularization $epsilon(bold(q))$, the matched-filter CTF approaches unity, implying perfect phase transfer.
This is misleading, since the MF noise variance is similarly increased:
  $
    op("Var")[tilde(phi)_text("MF")(bold(q))] = (op("Var")[tilde(phi)_text("OBF")(bold(q))])/ (sum_bold(k) abs(Gamma(bold(q),bold(k)))^2) = 1/(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2),
  $<eq-mf-var>
to obtain an SSNR which is identical to that of OBF:
$
  text("SSNR")_text("MF")(bold(q)) =  1/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$<eq-mf-ssnr>

This highlights an important subtlety: the statistically-reliable information content is the effectively the same for all three linear estimators we have explored so far, namely SSB, OBF, and MF/WDD.

#figure(
  image("vector/direct_gold_mos2.pdf",width: 100%),
  caption: [
    Direct methods reconstructions for *a)* near-focus MoS#sub[2] acquisition @zhang2025atom and *b)* defocused gold nanoparticle experimental datasets.
    Near-focus, iCOM, parallax, and SSB perform similarly.
    Note high-pass filtering was used to suppress low spatial frequency artifacts common in iCOM reconstructions.
    Inset scalebar 0.5 $"Å"^(-1)$.
    For defocused acquisitions, parallax and SSB perform much better than iCOM imaging, due to their ability to correct for aberrations. 
    The parallax and SSB gold reconstructions further benefit from upsampling.
    Inset scalebar 0.5 $"Å"^(-1)$.
    
  ],
  placement: auto,
  scope: "parent"
) <fig-exp-compare>

== Quadratic Approximation <sec-parallax>

The methods we have introduced so far all relied on the full aperture-overlap kernel $Gamma(bold(q),bold(k))$, which is expensive to compute numerically.
A natural question is whether a computationally efficient approximation exists that retains most of the information.

The _tilt-corrected bright-field (tcBF) STEM_ @Nguyen_2016 @Spoth_2017 @Yu_2025 or _parallax imaging_ @Varnavides_2023 @Varnavides_2024 @Varnavides_2025 method originated independently, based on the reciprocity principle.
Specifically, a virtual bright-field image formed form a given nonzero detector frequency during a defocused acquisition will appear laterally shifted in real space.
Computationally reversing this parallax effect, with subpixel accuracy using a detector-frequency-dependent phase ramp, restores all virtual BF images into a common focal plane, where they can be coherently summed @Yu_2025 @Varnavides_2025.

Formally, this parallax correction is equivalent to applying a phase factor $exp[upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)]$ to the virtual bright-field images, where $nabla_bold(k) chi(bold(k))$ is the gradient of the aberration surface at bright field frequency $bold(k)$.
To see connection with SSB explicitly, we Taylor-expand $Gamma(bold(q),bold(k))$ to first order in $bold(q)$:
#[
#show math.equation.where(block: true): set align(left)
$
  Gamma(bold(q),bold(k)) &approx Beta(bold(q),bold(k)) upright(e)^(upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)) \ 
  Beta(bold(q),bold(k)) &= A(bold(k))[A(bold(q-k))upright(e)^(-upright(i)chi(bold(q))) - A(bold(q+k))upright(e)^(upright(i) chi(bold(q)))],
$<eq-prlx-gamma-approx>
]

where $Beta(bold(q),bold(k))$ contains the aperture-overlap terms, while the remaining factor produces the parallax shift.
Thus, parallax imaging can be seen as a quadratic approximation to SSB, where only the first-order-aberrations-induced phase ramp is retained.

Combined with a global phase-flipping operation, parallax imaging provides a remarkably robust and computationally efficient approximation to SSB @Varnavides_2025:
#[
#show math.equation.where(block: true): set align(left)
$
  tilde(phi)_text("prlx")(bold(q)) = sum_bold(k) G(bold(q), bold(k)) thin op("sgn")[sin[chi(bold(q))]] thin upright(e)^(-upright(i) nabla_bold(k) chi(bold(k)) dot bold(q))
$<eq-par-recon>
]

The corresponding CTF is obtained by summing the omitted kernel $Beta(bold(q),bold(k))$ over the bright-field disk:
$
  text("CTF")_text("prlx")(bold(q)) &= upright(i)/2 sum_bold(k) Beta(bold(q),bold(k)) \
  &= -upright(i) sin[chi(bold(q))] [A star A](bold(q)), #label("equate:revoke")
$<eq-prlx-ctf>
which reduces to the axial-illumination CTF, modulated by the aperture autocorrelation function @Yu_2022 @Varnavides_2024 @Varnavides_2025.

Since the parallax estimator simply shifts each virtual bright-field image before coherently summing, the noise contributions retain unit variance.
Consequently, $op("Var")[tilde(phi)_text("prlx")(bold(q))]=1$ and the parallax SSNR is:
$
  text("SSNR")_text("prlx")(bold(q)) = abs(sin[chi(bold(q))]) [A star A](bold(q)),
$<eq-prlx-ssnr>

== First-Moment Projection <sec-icom>

An alternative and computationally efficient route to STEM phase retrieval is to take the first moment of the aperture–overlap function, known either as _integrated center-of-mass (iCOM) imaging_ or _integrated differential phase contrast (iDPC or DPC)_ @Dekkers_1974 @Lazic_2016.
Compared to other direct approaches, these are by far the most computationally-efficient and straightforward, although they do not provide the same aberration deconvolution advantages discussed above for the other direct approaches.

Starting from the WPOA CTF expression in @eq-ctf and using a vectorial detector response $D(bold(k)) = bold(k)$, we obtain the vector COM transfer function as:
$
  text("CTF")_text("COM")(bold(q)) &= upright(i)/2 integral Gamma(bold(q),bold(k)) thin bold(k) thin d bold(k) \
  &= (upright(i) thin bold(q))/2 [tilde(psi) star tilde(psi)](bold(q)), #label("equate:revoke")
$<eq-com-ctf>
i.e. the first moment of $Gamma(bold(q),bold(k))$ which is proportional to the probe autocorrelation weighted by $bold(q)$.

Fourier differentiation satisfies $cal(F)_(bold(r) arrow bold(q)){nabla_bold(r) phi(bold(r))} = upright(i) bold(q) thin tilde(phi)(bold(q))$, and thus we recognize the measured COM signal as a filtered estimate of the phase gradient, with the filter given by the probe autocorrelation.
To obtain the specimen phase, we Fourier-integrate the vector COM measurement to obtain:
$
  tilde(phi)_text("iCOM")(bold(q)) = sum_bold(k) (bold(q) dot [G(bold(q),bold(k)) thin bold(k)]) / (upright(i) abs(bold(q))^2).
$<eq-icom-recon>
Applying the same integration to the vectorial CTF yields the scalar iCOM transfer function:
$
  text("CTF")_text("iCOM")(bold(q)) = upright(i) [tilde(psi) star tilde(psi)](bold(q)),
$<eq-icom-ctf>
highlighting that iCOM reconstructs the specimen phase convolved with the probe autocorrelation @Bekkevold_2025.

The COM signal division by the spatial frequency, suggests the noise in the reconstruction scales with $abs(bold(q))$, to give the iCOM SSNR as @Varnavides_2025_ssnr:
$
  text("SSNR")_text("iCOM")(bold(q)) = (abs([tilde(psi) star tilde(psi)](bold(q))))/(abs(bold(q))).
$<eq-icom-ssnr>

@eq-icom-ssnr highlights that while the iCOM CTF suggests low spatial frequencies transfer with unit contrast, the corresponding SSNR shows these components become increasingly noisy in practice @Varnavides_2023 @Yu_2025 @Varnavides_2025_ssnr.

== Comparison of Direct Techniques

The phase estimators introduced above -- SSB, OBF, MF/WDD, parallax, and iCOM -- all originate from the same WPOA forward model in @eq-wpoa-forward and additive noise model in @eq-noise-model.
They primarily differ in i) how they weight the bright-field intensities, ii) how they normalize the coherent sum, and iii) how much of the aperture-overlap kernel they retain.

SSB performs an unnormalized coherent projection using the full aperture-overlap kernel.
OBF applies a noise-flattening scalar normalization.
MF/WDD implements the least-squares matched filter, either in detector-space (MF) or in a mixed-domain (WDD).
Parallax imaging uses a first-order approximation to the aperture-overlap kernel, keeping only the detector-frequency-dependent phase ramp $upright(e)^(upright(i) nabla_bold(k) chi(bold(k))dot bold(q))$, making it computationally cheap.
Parallax subpixel shift estimation accuracy enables scan step-size upsampling (@fig-uspsample), although this can be extended to other direct methods as well @Varnavides_2025.
Finally, iCOM bypasses the overlap-kernel entirely, and instead takes the first moment of the bright-field intensities and reconstructs the phase by Fourier-integration of the resulting COM signal.

#figure(
  image("vector/upsample.pdf",width: 100%),
  caption: [
    Upsampled 
    *a)* gold nanoparticles and *b)* apoferritin @Berk_2024 parallax reconstructions.
    Inset scalebars 0.5 $"Å"^(-1)$ and 0.5 $"nm"^(-1)$ respectively.
  ],
  placement: auto,
) <fig-uspsample>

With the exception of iCOM, these techniques rely on an accurate estimation of the aberrations, which can be calculated through optimization routines, based on self-consistency error @Varnavides_2025, or by least-squares fitting of linear systems of equations @Varnavides_2023 @Yu_2025.

@unified-pseudocode shows a unified pseudocode for the direct estimators we have seen so far, using a loop over bright-field pixels $bold(k)_text("BF")$.
This leverages the fact that the aperture-overlap function is identically zero outside the probe aperture, making it computationally efficient, and enabling natural upsampling via Fourier-tiling @Varnavides_2025.
It should be noted that, due to the mixed-domain requirement, WDD cannot be computed by solely looping over $bold(k)_text("BF")$.

As highlighted in @fig-ctf and @fig-exp-compare, the ideal approach depends on the nature of the data and acquisition parameters. 
For in-focus experiments, iCOM is often the preferred approach with the low computational overhead of this technique making it most compatible with in-situ approaches @bekkevold2024ultra.
Conversely, parallax reconstructions are often performed for defocused acquisitions using large step-sizes, e.g. for beam-sensitive biological samples @Berk_2024 @Yu_2025.

The SSB, OBF, and MF/WDD techniques perform a full deconvolution of the aperture-overlap and are also suited for acquisitions with residual higher-order aberration @Varnavides_2025 @Susi_2025.
However, acquisitions on aberration-corrected instruments are often dominated by first-order aberrations such as defocus and astigmatism, suggesting the quadratic approximation provided by parallax yields a nearly identical reconstruction as SSB, OBF, or MF/WDD @Varnavides_2025_ssnr.

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  placement: auto,
  // scope: "parent",
  pseudocode-list(
    booktabs:true,
    booktabs-stroke:0.5pt + black,
    line-numbering:none,
    hooks: .5em,
    numbered-title: [
      Unified direct STEM phase retrieval
    ]
  )[  
    *Inputs:* \
    • 4D-STEM dataset $I(bold(r),bold(k))$ \
    • estimator type $in {text("SSB"), text("OBF"), text("MF"), text("prlx"), text("iCOM")}$ \
    • integer upsampling factor $f$ \
    • aberration coefficients $C_(n,m)$  (for $chi$ and $nabla_bold(k) chi$) \
    • convergence semiangle $k_0$ \
    • scan/detector rotation angle $theta$

    *Output:* estimated phase upsampled by factor $f$

    *Initialization:* \
    • allocate $f$-upsampled output array $I'(bold(r)') arrow.l 0$ \
    • define bright-field index set $ bold(k)_text("BF") = {bold(k): abs(bold(k)) < k_0}$ \
    • extract bright-field stack $I_text("BF") = {I(bold(r),bold(k)) : abs(bold(k)) < k_0}$ \
    • construct upsampled and $theta$-rotated frequency grid $bold(q)'$
    
    *Reconstruction:* \
    + *for* each BF index $i=1$ to $N_text("BF")$:  
      + $G(bold(q) thick) arrow.l cal(F)_(bold(r) arrow bold(q)){ I_text("BF")[i](bold(r))}$  
          // #h(1fr) #text(rgb("#808080"))[(Fourier-transform vBF image)]  
      + $G(bold(q)') arrow.l op("tile")_f [G(bold(q))]$  
          // #h(1fr) #text(rgb("#808080"))[(upsample by Fourier tiling)]
      + $H(bold(q)') arrow.l cases(
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/abs(Gamma(bold(q)',bold(k)_text("BF"))) quad &"if SSB",
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/sqrt(sum_(bold(k)in bold(k)_text("BF"))abs(Gamma(bold(q)',bold(k)_text("BF")))^2) quad &"if OBF",
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/(sum_(bold(k in bold(k)_text("BF")))abs(Gamma(bold(q)',bold(k)_text("BF")))^2 + epsilon(bold(q)')) quad &"if MF",
        #h(0.85em) exp[-upright(i) nabla_bold(k) chi(bold(k)_text("BF")) dot bold(q)'] thin op("sgn")[sin[chi(bold(q)')]] quad &"if prlx",
        -upright(i) thin bold(k)_text("BF") dot bold(q)' \/ abs(bold(q))^2 quad &"if iCOM"
      )$ 
      // #h(1fr) #text(rgb("#808080"))[(compute estimator kernel)]
      + $I'(bold(r)') +#h(-0.1em)= Re[cal(F)^(-1)_(bold(q)' arrow bold(r)'){G(bold(q)') H(bold(q)')}] \/ N_text("BF")$ 
      // #h(1fr) #text(rgb("#808080"))[(apply kernel and accumulate)]
    + *end*\
  ],
) <unified-pseudocode>

For low-dose experiments, the direct phase-retrieval techniques perform remarkably well as compared to their more computationally expensive counterparts @Varnavides_2025_ssnr, suggesting that more advanced reconstruction approaches may not be needed offline.
However, for thick samples and experiments with higher electron fluence, iterative approaches outperform their direct phase retrieval counterparts as described in @sec-iterative.

= Iterative Ptychography <sec-iterative>

The direct phase-retrieval methods presented above provide fast, interpretable, and often remarkably robust reconstructions when multiple scattering is negligible.
However, applying STEM phase retrieval to complex materials science questions requires going beyond the WPOA.
Real specimens impart strong phase shifts, redistribute intensity nonlinearly, and may channel electrons through multiple atomic layers @Williams_2009 @Carter_2016 @Kirkland_2020.
These effects are fundamentally incompatible with the linear WPOA model, requiring _iterative methods_ based on the strong-phase object approximation, in which the specimen is modeled according to @eq-ms.

Iterative approaches offer several key advantages.
First, they enable super-resolution @Maiden_2009, allowing recovery of specimen information beyond the twice numerical-aperture limit of direct methods, and without imposing scan-step size restrictions.
Second, they are remarkably flexible: the same mathematical framework can be extended to incorporate depth-information @Chen_2021, multiple scattering channels (e.g. electrostatic and magnetic potentials @Varnavides_2023_mag), or partial-coherence in the converged illumination @Thibault_2013.
Third, iterative reconstructions do not require perfect prior knowledge of the converged illumination; they naturally support blind deconvolution, jointly solving for both the specimen phase and probe aberrations, albeit with improved reconstructions coming from a good initial guess.
Finally, the optimization framework underlying iterative approaches naturally interfaces with modern machine-learning tools, enabling reconstructions driven by autodifferentiation or deep generative priors @Lee_2025 @Gilgenbach_2025 @McCray_2025.

In the following sections, we develop the two major families of iterative methods, namely classical projection-based algorithms, and gradient-based approaches.
We show how the gradient-based approaches can be extended to multislice, mixed-state, and machine-learning–based formulations.

== Single-Slice Iterative Methods <sec-single-slice>

Iterative reconstruction methods begin from the strong-phase object approximation, in which the specimen is represented by a single transmission function related to the projected potential:
$
  cal(O)(bold(r)) = exp[upright(i) thin phi(bold(r))].
$<eq-spoa>
Unlike the WPOA, the detected bright-field intensities are no longer linear in $phi(bold(r))$.
for each scan position $bold(R)_j$, the exit wave and corresponding diffraction pattern are given by:
$
  psi_text("exit")^((j)) (bold(r)) &= cal(O)(bold(r)) psi(bold(r)-bold(R)_j) \ 
  I_text("model")^((j)) (bold(k)) &= abs(cal(F)_(bold(r) arrow bold(k)){psi_text("exit")^((j))(bold(r))})^2 = abs(tilde(psi)_text("exit")^((j))(bold(k)))^2
$<eq-spoa-intensities>

The goal of single-slice ptychography is to recover the complex-valued object $cal(O)(bold(r))$ and, often, refine the illumination probe $psi(bold(r))$, by enforcing consistency between the measured intensities $I_text("meas")^((j)) (bold(k))$ and the modeled intensities using the current estimates.

Each scan position must satisfy the nonlinear Fourier-modulus constraint $abs(tilde(psi)_text("exit")^((j))(bold(k))) = sqrt(I_text("meas")^((j))(bold(k)))$, which requires iterative algorithms alternating between real-space and Fourier space constraints.
These algorithms can be grouped in two broad families: proximal gradient / projection-set methods and gradient-based optimization methods @Varnavides_2023.

=== Proximal-Gradient / Projection-Set Methods <sec-projection-methods>

The earliest iterative ptychographic algorithms derive from classical phase-retrieval methods in crystallography and coherent diffractive imaging @Fienup_1982 @Levi_1984 @Miao_1999 @Bauschke_2002 @Elser_2003 @Thibault_2008.
These approaches frame reconstruction as finding an object-illumination pair $(cal(O),psi)$ lying in the intersection of two constraint sets: i) real-space constraint: the exit-wave must equal the product of the object and shifted illumination estimates, and ii) Fourier-modulus constraint: the exit-wave Fourier magnitude must match the measured intensities.

Algorithms such as _error reduction_ (ER) @Levi_1984, _difference map_ (DM) @Elser_2003 @Thibault_2008, and _relaxed averaged alternating reflections_ (RAAR) @Luke_2004, repeatedly project (and/or reflect) the exit wave between these two sets.
The canonical ER exit-wave update is given by @Bauschke_2002:
$
  psi'_text("exit")^((j))(bold(r)) &= cal(F)_(bold(k) arrow bold(r))^(-1) lr({ (sqrt(I_text("meas")^((j))(bold(k))))/abs(tilde(psi)_text("exit")^((j))(bold(k))) tilde(psi)_text("exit")^((j))(bold(k))}) \
  & equiv Pi_f [psi_text("exit")^((j))(bold(r))] #label("equate:revoke")\
$<eq-proj-exit-wave>
where the Fourier-projection operator $Pi_f$ replaces the Fourier exit-wave magnitude with the measured amplitude, retaining only its phase @Fienup_1982 @Bauschke_2002.
The object and probe updates follow from enforcing the real-space multiplicative constraint @Thibault_2008:
$
  cal(O)'(bold(r)) &= (sum_j psi^*(bold(r)-bold(R)_j) psi'_text("exit")^((j))(bold(r)))/(norm(psi(bold(r)-bold(R)_j))^2_alpha) \ 
  psi'(bold(r)) &= (sum_j cal(O)^*(bold(r)) psi'_text("exit")^((j))(bold(r)))/(norm(cal(O)(bold(r)))^2_alpha)
$<eq-proj-update>
where $alpha$ is a scalar 0-1 parameter controlling the maximum overlap weight in the $norm(dot)^2_alpha$ normalization.
$
  norm(dot)^2_alpha &= (1-alpha) sum_j abs(dot)^2 + alpha sum_j abs(dot)^2_text("max")
$<eq-normalization>
DM and RAAR combine projections in more sophisticated ways to form the exit-wave update given.
In-fact, we can parametrize a family of projection-set algorithms, using the scalar parameters $(a,b,c)$:
$
  psi'_text("exit")^((j))(bold(r)) = (1&-a-b) thin psi'_text("exit")^((j))(bold(r)) + a thin psi_text("exit")^((j))(bold(r)) \
  &+ b thin Pi_f [c thin psi_text("exit")^((j))(bold(r)) + (1-c) thin psi'_text("exit")^((j))(bold(r))]. #label("equate:revoke")
$<eq-proj-fam>
Named algorithms can then be recovered using specific $(a,b,c)$ combinations:
ER $(a=0,b=1,c=1)$ @Levi_1984, DM $(a=-1, b=1, c=2)$ @Elser_2003, and RAAR $(a=1-2 gamma, b=gamma, c =2)$ @Luke_2004, with relaxation parameter $gamma$.

Projection-set algorithms are robust and computationally simple, relying only on pointwise operations.
However, their relation to an explicit optimization problem is indirect, making them harder to generalize and sometimes slow to converge in low-redundancy or strong-scattering regimes @Varnavides_2023.

=== Gradient-Based Methods

A more modern view formulates ptychography as minimizing a data-fidelity loss.
For the amplitude-based noise model, the loss for a given exit wave is:
$
  cal(L) = sum_j norm(abs(tilde(psi)_text("exit")^((j))(bold(k))) - sqrt(I_text("meas")^((j))(bold(k))))^2.
$<eq-loss>

One of the earliest gradient-based ptychographic algorithms is the _extended ptychographic iterative engine_ (ePIE) @Maiden_2009, which performs block-wise stochastic gradient descent (SGD) in which each scan position provides a local loss and gradient update.
Modern approaches generalize this to true mini-batch optimization methods such as SGD and Adam @Lee_2025 @Gilgenbach_2025 @McCray_2025.

The amplitude loss in @eq-loss, corresponds to the _maximum a posteriori_ estimator under Gaussian detector noise with unit variance @Gilgenbach_2025.
Although electron detection is fundamentally Poissonian, at moderate electron counts the Gaussian approximation becomes valid, matching the same assumption used in the WPOA noise model @eq-noise-model.

Under this approximation, the exit-wave gradient has a closed-form expression, identical to the ER Fourier-magnitude projection:
$
  Delta psi_text("exit")^((j))(bold(r)) = Pi_f [psi_text("exit")^((j))(bold(r))] - psi_text("exit")^((j))(bold(r)).
$<eq-gd>

This can be used to update the object and illumination estimates using a form very similar to @eq-proj-update:
$
  cal(O)'(bold(r)) &= cal(O)(bold(r)) + beta (sum_j^J psi^*(bold(r)-bold(R)_j) Delta psi_text("exit")^((j))(bold(r)))/(norm(psi(bold(r)-bold(R)_j))^2_alpha) \
  psi'(bold(r)) &= psi(bold(r)) + beta (sum_j^J cal(O)^*(bold(r)) Delta psi_text("exit")^((j))(bold(r)))/(norm(cal(O)(bold(r)))^2_alpha).
$<eq-sgd-update>

Gradient-based methods offer clear statistical interpretability, support batching and adaptive learning rates, and integrate naturally with extensions such as multislice, mixed-state, and parametric probe models.
Unlike projection-set methods, they make the optimization landscape explicit, enabling principled regularization and convergence diagnostics.

@fig-iterative illustrates the advantages of iterative phase retrieval over direct methods across several experimental datasets spanning different materials classes, using the aberration coefficients optimized in @fig-exp-compare.
In each case, iterative ptychography yields improved contrast, reduced artifacts, and more faithful recovery of structural features.

#figure(
  image("vector/iterative.pdf",width: 100%),
  placement: top,
  scope: "parent",
  caption: [
    Iterative ptychography reconstructions of
    *a)* apoferritin @Berk_2024, *b)* MoS#sub[2] @zhang2025atom, and *c)* gold nanoparticles on amorphous carbon. 
    Aberrations coefficients were initialized using direct ptychography reconstructions in @fig-exp-compare and @fig-uspsample.
  ]
) <fig-iterative>

=== Transfer of Information

Although iterative ptychography does not admit simple closed-form CTF/SSNR like the direct methods, several useful observations can be made @Varnavides_2025_ssnr:

+ With a reasonably accurate probe guess, the first iteration update of ePIE/SGD effectively performs probe deconvolution under the WPOA, yielding a CTF similar to the SSB CTF.
+ As iterations proceed, the effective CTF fills in information, approaching unity everywhere.
+ Numerical tests reveal that the low-frequency SSNR of iterative ptychography matches SSB.
  At higher frequencies, the SSNR plateaus to $sqrt(2)\/2$, consistent with recent Fisher information limits which suggest a STEM DQE ceiling of 1/2 @Dwyer_2024 @Vega_2025 @Varnavides_2025_ssnr.

Together, these observations show that although iterative ptychography can achieve super-resolution, the statistical information content is similar to direct linear methods at low spatial frequencies, with predictable saturation at intermediate frequencies.

== Beyond Single-slice Ptychography <sec-beyond-ss>

The flexibility of iterative ptychography becomes especially powerful once we move beyond the single-slice, single-probe approximation used in the earlier sections.
Real experiments often deviate from this idealization: illumination is never perfectly coherent, specimens may be tens to hundreds of nanometers thick, and additional physical channels such as magnetization and inelastic excitations contribute to the detected intensity.
Iterative methods can incorporate these complexities directly into the forward model, allowing reconstructions that remain accurate well outside the WPOA regime.

As these models grow in complexity, the reconstruction problem becomes more ill-posed necessitating robust regularization.
Classical regularizers stabilize the solution by encouraging smoothness, sparsity, physical consistency, or low-rank structure @Varnavides_2023. 
Machine-learning approaches replace such hand-designed priors with learned generative models or implicit architectural biases, often yielding cleaner and more robust reconstructions, requiring less hyperparameter tuning @McCray_2025.

In practice, high-resolution reconstructions of many materials systems almost always rely on some combination of multislice propagation, mixed-state probe modeling, and regularization.
These ingredients are essential for moving beyond the WPOA and unlocking the full information content of modern 4D-STEM experiments.

=== Partial Coherence

The first major generalization is using a mixed-state illumination @Thibault_2013 @Chen_2020, which relaxes the assumption of a single, fully coherent probe.
Instead, the illumination intensity is modeled as an incoherent mixture of mutually-orthogonal probes @Odstrcil_2016:
$
  psi_text("exit")^((j,l)) (bold(r)) &= cal(O)(bold(r)) psi^((l))(bold(r)-bold(R)_j) \ 
  I_text("model")^((j)) (bold(k)) &= sum_l abs(cal(F)_(bold(r) arrow bold(k)){psi_text("exit")^((j,l))(bold(r))})^2 
$<eq-mixed-state>

The formalism naturally models partial spatial and temporal coherence of the electron source, including energy spread and finite source size.
In the reconstruction loop, mixed-state ptychography jointly updates the object and all probe modes so that their incoherent sum matches the measured intensity according to @eq-mixed-state.

The expressiveness of @eq-mixed-state comes at the risk of overfitting unphysical probes, necessitating strong regularization.
Conventional approaches impose orthogonality, sparsity, or low-rank constraints on the probe modes @Odstrcil_2016 @Varnavides_2023, whereas machine-learning-based reconstructions require fewer hard constraints due to their implicit regularization @McCray_2025.

=== Depth Information

A second often-necessary extension is the multislice approximation, which models strong multiple scattering in thicker specimens using @eq-ms-both.
Specifically, the modeled intensities for $N$ slices are given by:
$
  psi_text("exit")^((j,n)) (bold(r)) &= cal(O)^((n))(bold(r)) psi^((n))(bold(r)-bold(R)_j) \
  psi^((n))(bold(r)) &= op("Prop")_(Delta z)[psi^((n-1))(bold(r))] text("for") n gt.eq 2\
  I_text("model")^((j)) (bold(k)) &= abs(cal(F)_(bold(r) arrow bold(k)){psi_text("exit")^((j,N))(bold(r))})^2 
$<eq-multi-slice>

Multislice ptychography is crucial for quantitative imaging of materials far outside the weak-scattering regime, including thick crystals, buried interfaces, and defect structures @Ribet_2024.
By explicitly modeling dynamical diffraction, the multislice framework mitigates systematic errors that appear when single-slice reconstructions attempt to explain multiple scattering using only a 2D projected potential.

As with mixed-state ptychography, this increased expressive power introduces additional degrees of freedom.
Explicit regularization along the beam direction helps stabilize the reconstruction, with machine-learning-based approaches relying on the implicit regularization of the network architecture  @McCray_2025.

Combining ptychography with tomography can substantially improve multislice depth resolution @chen2024imaging @allars2025depth.
Approaches such as few-tilt aperture synthesis and joint ptychography-tomography optimization recover complementary angular information, reducing the ambiguities inherent to purely depth-slicing multislice reconstructions @Lee_2023 @You_2024 @Dong_2025.
These hybrid methods achieve more accurate 3D reconstructions and mitigate slice-mixing artifacts, particularly in thick or compositionally heterogeneous specimens.

= Outlook

The ability of phase-retrieval techniques to recover weak scattering signals makes the approaches described here broadly applicable across materials science and engineering.
They are particularly well suited for beam-sensitive, low-atomic-number specimens such as polymers @bardot2025mechanically, biological structures @Berk_2024 @Yu_2025 @Spoth_2017, and hard–soft composites including metal–organic frameworks @Ma_2025 @shen2020imaging and DNA origami @ding2022three.
Phase retrieval methods are also increasingly applied to inorganic materials, where they enable sensitivity to subtle structural variations of light elements in functional systems relevant to energy and quantum science @lozano2018low @kp2025electron.
Common specimens include nanoparticles @shi2025electron @Ribet_2024 @Varnavides_2023, one-dimensional nanostructures such as nanotubes @yang2016simultaneous @pelz2023solving, two-dimensional materials @jiang2018electron @o2022increasing @Susi_2025 @byrne2025fabrication @zhang2025atom, thin films @dong2025sub, and cross-sectional views of thicker crystalline samples @scheid2025atomic @chen2024imaging. 

Recent work has demonstrated that ptychographic phase retrieval can be performed even on uncorrected instruments @nguyen2024achieving, including at low accelerating voltages and small convergence angles @blackburn2025sub.
Nevertheless, successful phase retrieval remains experimentally demanding, and in practice most samples benefit substantially from aberration correction.
Adequate overlap in reciprocal space is essential to ensure a unique and accurate reconstruction, and phase retrieval workflows in materials science still largely rely on advanced hardware, including fast pixelated detectors and aberration-corrected probes.

As discussed for both direct and iterative approaches, defocused acquisitions can improve information transfer in phase retrieval experiments. 
However, selecting suitable experimental parameters remains challenging: reliable convergence depends sensitively on defocus, probe size, and scan step, while accurate estimation of the applied defocus can be nontrivial, especially for thick specimens. 
Estimating the defocus value applied during an experiment can be challenging, especially for thicker samples. 
These challenges are exacerbated in very low-dose experiments, where data may need to be acquired blindly and image quality assessed only through post-processing. 

Direct reconstruction techniques are computationally efficient and can often be performed live during data acquisition using modern hardware @Yu_2022 @Ooe_2021 @Pelz_2022 @Strauch_2021. 
Such on-the-fly reconstructions are valuable for optimizing experimental parameters, verifying sample thickness, and detecting beam damage in real time.
In typical workflows, direct phase retrieval is used during acquisition, while more computationally intensive iterative reconstructions, especially those involving multislice propagation or mixed-state modeling, are carried out offline on GPU-equipped workstations and high-performance computer clusters.

Looking forward, key challenges include extending phase retrieval to thicker specimens, larger fields of view, and higher-dimensional datasets that combine phase retrieval with tomography, spectroscopy, or time-resolved measurements, as well as adapting these methods to an increasingly diverse range of microscope configurations. 
Many groups are already pushing to extend these techniques through both hardware and software advances, which will allow for more advanced materials characterization in the near future.

= Acknowledgement 
Work at the Molecular Foundry was supported by the Office of Science, Office of Basic Energy Sciences, of the U.S. Department of Energy under Contract No. DE-AC02-05CH11231.


= Data availability
The experimental data and reconstruction notebooks are freely available #link("https://drive.google.com/drive/folders/1TNlqmMsiHQPIMZ5UW42MSd0yy6W9gnEL?usp=sharing")[
  here
].


// #text(mrs-col)[
//   *Total number of words is #total-words.*
// ]

#bibliography(
  "references.bib",
  style: "american-chemical-society"
)