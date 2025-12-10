#import "@preview/pubmatter:0.2.2"
#import "@preview/lovelace:0.3.0": pseudocode-list

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
      Conventional STEM imaging, however, is limited by the phase problem, whereby the phase of the electron exit wave is lost upon intensity detection.
      Recent advances in diffractive imaging and 4D-STEM have enabled a range of phase retrieval techniques that computationally reconstruct the missing information.
      These approaches offer improved dose efficiency and enhanced  sensitivity to weakly scattering signals, extending quantitative imaging to beam-sensitive materials with light elements.
      In this review, we introduce the phase problem in electron microscopy and survey the diverse landscape of phase retrieval techniques used in the field.
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
  footer: pubmatter.show-page-footer(fm)
)
#show cite: it => text(fill: mrs-col, it)
#show ref: it => text(fill: mrs-col, it)

#pubmatter.show-title-block(fm)
#pubmatter.show-abstract-block(fm)

// Page Formatting
#set text(font: "Noto Serif", size: 9pt)
#set par(justify: true)
#show heading: set text(mrs-col)   
#set math.equation(numbering: "(1)", supplement: "Eq.")

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

// Accents
#let diaer = "\u{308}"

= Introduction

Scanning transmission electron microscopy (S/TEM) enables the characterization of specimens from the micron scale down to the atomic scale, making it an indispensable characterization tool for any materials scientist @Williams_2009.
S/TEM instruments operate in two complimentary acquisition modalities: _imaging mode_, which produces a magnified real-space image of the specimen, and _diffraction mode_, which records the angular distribution of scattered electrons in reciprocal-space @Carter_2016.

Traditional parallel-illumination TEM imaging is widely used across disciplines, from high-resolution studies of frozen-hydrated biomolecules @Vinothkumar_2016 to lattice-resolved @Alcorn_2023 and defect imaging @Fultz_2013 in materials.
In contrast, STEM employs a highly converged electron probe containing a broad range of incident wavevectors. 
When this probe interacts with the specimen, it produces a diffraction pattern that encodes the local scattering. 
In this sense, STEM is inherently a diffraction-mode technique, although real-space images are obtained by processing the resulting position-resolved diffraction patterns -- a process we will refer to as _diffractive imaging_.
This approach routinely provides interpretable, atomic-resolution imaging of crystalline materials and forms the basis of modern materials characterization @Ophus_2023.

Both modalities are fundamentally limited by the microscopy "phase problem," which suppresses contrast from weakly scattering specimens and limits quantitative interpretation.
In this review, we focus on the mathematical foundations of STEM phase-retrieval techniques, which reconstruct the missing phase and thereby overcome these intrinsic contrast limitations.
We emphasize the implications of these methods for quantitative materials characterization and set the stage for a unified treatment of the underlying physics.

#figure(
  rect(
    width: 100%,
    height: 180pt
  )[
    Placeholder for schematic figure showing:\
    a) planewave TEM + phase-plate geometry,\
    b) nanobeam 4DSTEM geometry, and \
    c) diffractive imaging geometry
  ],
  caption: [
    \@Steph
  ],
  placement: top
) <fig-schematic>

== Microscopy Phase Problem

The phase problem arises in electron microscopy because the scattered electron wavefunction -- the "exit wave" -- is complex-valued, yet physical detectors measure only real-valued intensities @Fienup_1982.
In other words, although the specimen primarily imprints a _phase shift_ on the complex incident electron wavefunction $psi$, the detector records only $abs(psi)^2$, seemingly discarding the information that carries most of the specimen's structure.

For S/TEM, this becomes clear in the wave propagation formalism.
The evolution of an electron wavefunction, $psi(bold(r))$, along the optical axis $z$ is governed by the Schro#diaer;dinger equation for fast electrons @Kirkland_2020:

$
  (partial psi(bold(r))) / (partial z) = (upright(i) lambda)/(4 pi) nabla_(x y)^2 psi(bold(r)) + upright(i) sigma V(bold(r)) psi(bold(r)),
$ <eq-shrodinger>
where $lambda$ is the relativistic wavelength, $sigma$ the interaction constant, $nabla_(x y)^2$ the in-plane Laplacian operator, and $V(bold(r))$ the specimen electrostatic potential.
The two terms on the right-hand side of @eq-shrodinger represent the propagation and potential operators respectively.
Because these operators do not commute, numerical solutions typically use the multislice method @Cowley_1957.
The specimen is partitioned into $n$ thin slices, and the wavefunction is updated by alternating between transmission through each slice and free-space (Fresnel) propagation @Kirkland_2020:
$
  psi_(n+1)(bold(r)) & = exp[(upright(i) lambda Delta z)/(4 pi) nabla_(x y)^2]exp[upright(i) sigma V_n^(Delta z)(bold(r))] psi_n(bold(r)), \
  V_n^(Delta z)(bold(r)) &= integral_(z_n)^(z_n + Delta z) V(bold(r)) d z.
$ <eq-ms>
Inspecting @eq-ms shows that the specimen enters solely through a multiplicative phase factor $exp[upright(i) sigma V_n^(Delta z)(bold(r))]$.
Electrons are not  absorbed by the specimen (ignoring weak inelastic losses); any apparent amplitude modulation simply reflects electrons scattered outside the acceptance angle of the detector.
Thus, the structural information of interest to materials scientists is encoded in the phase of the exit wave, not its magnitude. 
Recovering the exit wave phase from intensity-only measurements is therefore the central challenge.

== Phase Contrast Imaging

A direct approach to the microscopy phase problem is to leverage the imaging optics to convert otherwise imperceptible phase variations in the exit wave into measurable intensity variations in the imaging plane.
This approach, _phase contrast imaging_ (PCI) @Carter_2016, is most naturally implemented in planewave TEM, where the post-specimen objective lens forms a magnified real-space image of the specimen.

To illustrate the basic principle, we restrict our attention to weakly-scattering specimens satisfying the _weak phase object approximation_ (WPOA), for which the exit wave can be written as @Vulovic_2014:
$
  psi_text("exit")(bold(r)) approx 1 + upright(i) sigma V_p (bold(r)) + cal(O)(sigma^2 V_p^2(bold(r))),
$ <eq-wpoa>
where $V_p (bold(r)) = integral_(-infinity)^infinity V(bold(r)) d z$ is the projected potential and we drop terms quadratic in the interaction contract.
In this regime the specimen modifies only the phase of the electron wavefunction, so additional optical manipulations are required to convert phase changes into measurable amplitude contrast.

=== Defocus Phase Contrast

The simplest such manipulation is intentional over- or under-focus of the objective lens.
Defocus by a value $Delta f$ multiplies the exit wave in reciprocal space by a quadratic phase factor given by,
$
  tilde(psi)'(bold(q)) = exp[-upright(i) pi lambda Delta f abs(bold(q))^2] tilde(psi)(bold(q)).
$ <eq-defocus>
Transforming this to real-space and expanding to first order in $sigma V_p (bold(r))$, the image intensity becomes:
$
  I(bold(r)) approx 1 - 2 sigma [V_p (bold(r)) convolve.o h_(Delta f)(bold(r))],
$
where $h_(Delta f)(bold(r)) = cal(F)^(-1)_(bold(q) arrow bold(r)) {sin[pi lambda Delta f abs(bold(q))^2]}$ is the real-space convolution kernel corresponding to @eq-defocus and $convolve.o$ represents the convolution operation.
Defocus thus converts sample-induced phase variations into intensity contrast through a sinusoidal convolution, leading to characteristic contrast reversals with increasing spatial frequency.

=== Phase-Plate Contrast

Another approach is to introduce a post-specimen phase shift using a phase plate.
This originates from optical microscopy, where Frits Zernike's phase-contrast microscope earned the Nobel prize in Physics for its transformative impact on biological imaging @Zernike_1942.
An ideal phase plate shifts the unscattered beam by $pi\/2$:
$
  tilde(psi)'(bold(q)) = cases(
    upright(i) tilde(psi)(bold(q)) &"if" bold(q) = bold(0),
    tilde(psi)(bold(q)) &"otherwise"
  ). 
$ <eq-zernike>
Expanding again to first order in $sigma V_p (bold(r))$, the corresponding image intensity is given by:
$
  I(bold(r)) approx 1 + 2 sigma V_p (bold(r)),
$
showing that a phase plate enables direct, linear transfer of the specimen phase into image intensity.

@fig-pci illustrates these effects for a simulated arrangement of single- and double-walled carbon nanotubes (CNTs) acquired at low dose. 
The in-focus HRTEM image shows almost no contrast.
Defocus improves visibility but introduces frequency-dependent contrast reversals, causing different regions of the CNTs to appear in or out of focus.
By contrast, Zernike phase contrast robustly recovers both the high-resolution lattice information and the low-frequency envelope distinguishing the CNTs from the vacuum background.

#figure(
  image("raster/phase_contrast_imaging_CNTs.png",width: 100%),
  caption: [
    High-resolution TEM imaging *a)* of simulated single- and double-walled carbon nanotubes, acquired with an electron dose of 500 e/\u{00C5}#super[2]  using:
    *b)* in-focus optics, *c)* 50 nm of over-focus, and *d)* an ideal Zernike phase plate.

  ],
  placement: top
  
) <fig-pci>

== Diffractive Imaging

As discussed above, STEM is inherently a diffraction-based technique: at each probe position $bold(R)$, we have access to the diffraction intensity $I(bold(R),bold(k)) = abs(tilde(psi)_text("exit")(bold(R),bold(k)))^2$, where $bold(k)$ is the in-plane scattering vector.
Historically, STEM has used monolithic annular detectors that integrate this intensity within annular collection limits to form a real-space image.
A conventional annular signal is therefore given by:
$
  I_text("ann")(bold(R)) = integral_(theta_text("in"))^(theta_text("out")) I(bold(R),bold(k)) d bold(k),
$
yielding familiar contrast modes such as bright-field (BF), annular bright-field (ABF), annular dark-field (ADF), and high-angle annular dark-field (HAADF) STEM @Crewe_1970 @Pennycook_1991.
These images are highly interpretable -- especially for crystalline materials -- leading to their prevalence in materials science characterization. 
However, they discard the structural information encoded in the exit-wave phase.

The development of fast, low-noise direct electron detectors has enabled recording the full diffraction pattern $I(bold(R),bold(k))$ at every scan position, giving rise to a family of techniques collectively known as 4D-STEM @Levin_2021 @Ophus_2019.
These datasets retain the full diffractive signature of the probe–specimen interaction, far beyond what can be accessed with scalar annular signals.
In what follows, we focus on the subset of 4D-STEM methods that use these position-resolved diffraction intensities to recover the specimen phase.
We will refer to this class of approaches collectively as diffractive imaging, or STEM _phase retrieval_ techniques @sanchez2025.

=== Weak Phase Object Approximation

Under the WPOA in @eq-wpoa, the specimen transmission function is $t(bold(r)) approx 1 + upright(i) sigma V_p (bold(r))$, with the Fourier transform of the scattered component given by $tilde(phi)(bold(k)) = cal(F)_(bold(r) arrow bold(k)){sigma V_p (bold(r))}$.
In this regime, the diffraction intensity can be written as the self-convolution of the converged probe illumination $tilde(psi)(bold(k))$ with the weak object term @Rodenburg_1993:
$
  I(bold(R),bold(k)) = integral integral tilde(psi)(bold(k')) tilde(phi)(bold(k-k')) tilde(psi)^*(bold(k''))tilde(phi)^*(bold(k-k'')) exp[2 pi upright(i) bold(R) dot (bold(k'-k''))] d bold(k') d bold(k'').
$ <eq-conv>
Following #cite(<Rodenburg_1993>,form: "author"), it is convenient to take the Fourier transform of the measured intensities with respect to the scan position: $G(bold(q),bold(k)) = cal(F)_(bold(R) arrow bold(q)){I(bold(R),bold(k))}$, where $q$ resents the fourier transform of the real space vector $r$.
Using the WPOA property $tilde(phi)(bold(k)) = - tilde(phi)^*(-bold(k))$ @Rodenburg_1993, one obtains the compact form @Yang_2016:
$
  G(bold(q),bold(k)) &= abs(tilde(psi)(bold(k)))^2 delta(bold(q)) + Gamma(bold(q),bold(k)) tilde(phi)(bold(q)) \
  Gamma(bold(q),bold(k)) &equiv tilde(psi)^*(bold(k))tilde(psi)(bold(k-q)) - tilde(psi)(bold(k))tilde(psi)^*(bold(k+q)),
$<eq-wpoa-forward>
where the aperture overlap function $Gamma(bold(q),bold(k))$ encapsulates the probe geometry and forms the basis of all direct STEM phase retrieval methods.
@fig-gamma shows characteristic views of $Gamma(bold(q),bold(k))$ for a defocused converged probe with a circular aperture.

We take the probe to have the form $tilde(psi)(bold(k)) = A(bold(k)) upright(e)^(-upright(i) chi(bold(k)))$, where
$A(bold(k))$ is a normalized top-hat function describing the probe-forming aperture and $chi(bold(k))$ is the aberration surface given by:

$
  chi(k,theta) = (2 pi) / lambda sum_(n,m) 1 / (n+1) C_(n,m) (k lambda)^(n+1) cos[m(theta - theta_(n,m))]
$ <chi-eq>

where $k = abs(bold(k))$, $theta = arctan[bold(k)]$, $n$ and $m$ are radial and azimuthal orders of the coefficients $C_(n,m)$ with  axis $theta_(n,m)$.

#figure(
  image("raster/mrs-bulletin-fig2.png",width: 100%),
  caption: [
    Components of the aperture overlap function, $Gamma(bold(q),bold(k))$.
    *a)* Probe forming aperture with (bottom) and without (top) aberration function at the back focal plane. 
    *b)* Slicing along spatial frequencies $bold(q)$ and plotting over the detector frequencies $bold(k)$, highlights the so-called "double" and "triple" overlap "trotter" regions.
    *c)* Slicing along detector frequencies $bold(k)$ and plotting over the spatial frequencies $bold(q)$, illustrates the effect of shifting the probe aperture and aberrations.
  ],
  placement: top
) <fig-gamma>

=== Transfer of Information

Under the WPOA, STEM image formation is linear in the specimen phase.
This allows us to define a contrast transfer function (CTF), $cal(L) (bold(q))$, describing how well spatial frequencies of the specimen are transmitted or, in the context of STEM phase retrieval techniques, how faithfully they can be reconstructed.
We write the reconstructed phase as:
$
  tilde(psi)_text("rec")(bold(q)) &= 2 tilde(phi)(bold(q)) times cal(L)(bold(q)),
$
where the factor of 2 follows common conventions @Dwyer_2024 @Vega_2025.
An ideal phase retrieval method would therefore satisfy $cal(L)_text("ideal")(bold(q)) =1$.
For an arbitrary detector response function $D_j (bold(k))$ (with $j$ indexing a detector pixel or segment), #cite(<Hammel_1995>,form: "author") showed that the complex-valued CTF is @Hammel_1995 @rose_1977
$
  cal(L)_j (bold(q)) = i /2 integral D_j (bold(k)) [tilde(psi)^*(bold(k)) tilde(psi)(bold(q-k))  - tilde(psi)(bold(k)) tilde(psi)^*(bold(q+k))] d bold(k).
$ <eq-ctf>

For a pixelated detector, $D_j (bold(k)) = delta(bold(k))$, the integrand reduces to the aperture-overlap function $Gamma(bold(q),bold(k))$.
More compact expressions follow from an asymmetric decomposition of cross-correlations @Bekkevold_2025 @Lazic_2017
$
  Re{cal(L)_j (bold(q))} &= 1/2 {[psi star psi D_j](bold(q)) + [psi D_j star psi](bold(q))}\
  Im{cal(L)_j (bold(q))} &= 1/2 {[psi star psi D_j](bold(q)) - [psi D_j star psi](bold(q))},
$ <eq-ctf-corr>
where $star$ denotes cross-correlation and $Re$ and $Im$ represent real and imaginary components respectively.

Two limiting cases of @eq-ctf provide further physical insight.
In the absence of aberrations, $chi(bold(k))=0$, the real-part of @eq-ctf-corr vanishes and the imaginary part reduces to the aperture auto-correlation:
$
  cal(L)_text("in-focus")(bold(q)) = upright(i) [A star A](bold(q)) = upright(i) Re[cal(F)^(-1)_(bold(r)arrow bold(q)){abs(cal(F)_(bold(q)->bold(r)){A(bold(q))})^2}].
$<eq-infocus-ctf>
This envelope is a fundamental limit for all direct STEM phase retrieval methods.
Similarly, evaluating @eq-ctf for the axial illumination case, $bold(k)=0$, yields a purely imaginary CTF:
$
  cal(L)_text("axial")(bold(q)) = -upright(i) sin[chi(bold(q))],
$
which is precisely the HRTEM CTF derived in the previous section.
This result is often described as _reciprocity_ between TEM and STEM techniques.

=== Statistically Reliable Information

The CTF only describes the maximum transferable signal, not the statistical reliability of that signal under noise.
A complete description of information transfer must account for noise statistics, notably Poisson shot noise in direct-electron detectors.
The natural figure of merit is the spectral signal-to-noise ratio (SSNR) @Unser_1987 @Varnavides_2025_ssnr,
$
  text("SSNR")(bold(q)) = (abs(chevron.l tilde(psi)(bold(q)) chevron.r))/sqrt(op("Var")[tilde(psi)(bold(q))]),
$
which quantifies the statistically reliable recoverable information at each spatial frequency.
The SSNR formalism is related to the detective quantum efficiency (DQE), recently introduced as a quantitative performance metric for STEM phase retrieval @Bennemann_2025:
$
  text("DQE")(bold(q)) = (text("SSNR")_text("out")^2 (bold(q))) / (text("SSNR")_text("in")^2 (bold(q)) ),
$ <dqe-eq>
where $text("SSNR")_text("in")(bold(q))$ is the SSNR of an "ideal" reference system, typically taken as HRTEM with a Zernike phase plate @Zernike_1942 @Vega_2025.
Thus, the DQE provides a normalized, absolute measure of how efficiently a STEM method transfers information relative to a theoretical optimum.

= Direct Phase Retrieval Techniques

Equipped with the WPOA aperture-overlap and CTF/SSNR formalisms, we are now ready to investigate the zoo of direct STEM phase retrieval methods and their various acronyms.
These differ primarily in how they combine the Fourier-transformed measured diffraction intensities $G(bold(q),bold(k))$ to produce an estimate for $tilde(phi)(bold(q))$.

== Phase-Compensated Coherent Summation <sec-ssb>

The first technique we will investigate goes by two seemingly unrelated names: _aberration-corrected bright-field (acBF) STEM_ @Ma_2025 and _phase-compensated single-sideband (SSB) ptychography_ @Yang_2016.
The former highlights its close connection to _tilt-corrected bright-field (tcBF) STEM_, which we investigate further in @sec-parallax.
The latter name reflects the structure of the WPOA forward model in @eq-wpoa-forward, which contains two redundant contributions at $bold(q)$ and $-bold(q)$.

In the absence of aberrations, these two "sidebands" are related by complex conjugation (Friedel's law @Friedel_1913), so the specimen phase $tilde(phi)(bold(q))$ can be reconstructed using using only one of them.
In practice, once aberrations are present, the two sidebands are no longer perfect conjugates: residual aberrations imprint an additional geometric phase to the aperture-overlap function $Gamma(bold(q),bold(k))$.

The key insight behind SSB is that, under the WPOA, detector pixels sampling the same sideband carry the same specimen phase $tilde(phi)(bold(q))$.
Differences between pixels arise only from known, instrument-dependent phases, namely aberration-induced geometric phases and aperture-overlap geometry.
If these extraneous phases are removed, all sideband contributions from all detector pixels can be added coherently.

Phase-compensated SSB accomplishes this by dividing $Gamma(bold(q),bold(k))$ by its magnitude and retaining only its unit-modulus phase factor, effectively rotating each detector-plane frequency into a common phase reference.
The estimated phase is then obtained by coherently summing all phase-aligned detector samples @Yang_2016:
$
  tilde(phi)_text("SSB")(bold(q)) = sum_bold(k) (Gamma^*(bold(q),bold(k)))/(abs(Gamma(bold(q),bold(k)))) G(bold(q), bold(k)).
$<eq-ssb-recon>

This operation discards the magnitude of $Gamma(bold(q),bold(k))$  and uses only its phase.
It works remarkably well and remains one of the most widely used direct phase retrieval techniques.
Inserting the forward model $G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q))$ into @eq-ssb-recon gives the SSB CTF @Yang_2016:
$
  cal(L)_text("SSB")(bold(q)) = upright(i)/2 sum_bold(k) abs(Gamma(bold(q),bold(k))).
$
For spatial frequencies beyond the aperture semiangle $abs(bold(q)) > q_0$, the overlap $Gamma(bold(q),bold(k))$ reduces to the "double-overlap" region, and the CTF collapses to the ideal autocorrelation enveloped derived in @eq-infocus-ctf.

To understand the SSB noise term, note that each detector frequency contributes a noisy measurement:
$
  G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q)) + n(bold(q),bold(k)), 
$ <eq-noise-model>
with unit-variance noise $n(bold(q),bold(k))$ @Bennemann_2025.
The phase-alignment step preserves unit noise variance, so noise contributions add incoherently, while the signal adds coherently.
Thus, the total variance at each spatial frequency $bold(q)$ is simply the number of detector pixels for which $Gamma(bold(q),bold(k))$ is nonzero: 
$
op("Var"[tilde(phi)_text("SSB")(bold(q))]) = sum_bold(k) 1_(\{abs(Gamma(bold(q),bold(k))) >0\})  = 2 D(bold(q)) + T(bold(q)),
$
where $D(bold(q))$ and $T(bold(q))$ are the double and triple overlap regions (@fig-gamma).
The resulting SSNR is therefore:
$
  text("SSNR")_text("SSB")(bold(q)) = (sum_bold(k) abs(Gamma(bold(q),bold(k)))) / (2 sqrt(2 D(bold(q)) + T(bold(q))))
$

#figure(
  rect(
    width: 100%,
    height: 200pt
  )[
    Placeholder for direct methods figure (CTFs and SSNRs)?
  ],
  placement: top
) <fig-ctf>

== Noise-Flattening Normalization <sec-obf>

Phase-compensated SSB improves robustness against residual aberrations by removing the geometric phase of the aperture-overlap function before summing detector-plane frequencies.
However, SSB still treats all contributing detector pixels equally, even though the strength of the aperture overlap varies strongly across the BF disk, resulting in a sub-optimal reconstruction.

The _optimum bright-field (OBF) STEM_ method addresses this by applying a noise-matched normalization to the SSB estimator @Ooe_2021 @Ooe_2024.
Starting from the phase-aligned numerator $sum_bold(k) Gamma^*(bold(q),bold(k)) G(bold(q),bold(k))$, OBF introduces a scalar normalization factor proportional to the root-mean-squared aperture overlap strength to obtain:
$
  tilde(phi)_text("OBF")(bold(q)) =  (sum_bold(k)Gamma^*(bold(q),bold(k)) G(bold(q), bold(k)))/sqrt(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2).
$<eq-obf-recon>

The denominator rescales the coherent SSB sum by the effective signal-to-noise ratio (SNR) of the bright-field detector region.
For each spatial frequency, this normalization prevents a small subset of bright-field pixels with weak overlap from amplifying noise.
Thus, OBF can be viewed as a noise-flattened SSB formulation, retaining geometric phase compensation but adjusting its gain to reflect information reliability.

Substituting the forward model $G(bold(q),bold(k)) = Gamma(bold(q),bold(k)) tilde(phi)(bold(q))$ into @eq-obf-recon gives the OBF CTF:
$
  cal(L)_text("OBF")(bold(q)) = upright(i)/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$

Using the additive unit-variance noise model from @eq-noise-model, the OBF estimator numerator becomes:
$
  sum_bold(k) Gamma^*(bold(q),bold(k)) G(bold(q),bold(k)) = sum_bold(k) abs(Gamma(bold(q),bold(k)))^2 tilde(phi)(bold(q)) + sum_bold(k) Gamma^*(bold(q),bold(k)) n(bold(q),bold(k)),
$
with the second term describing the additive noise contributions with total variance:
$
  op("Var")[sum_bold(k) Gamma^*(bold(q),bold(k)) n (bold(q),bold(k))] = sum_bold(k) abs(Gamma(bold(q),bold(k)))^2.
$
This is precisely the square of the OBF denominator, which normalizes the OBF variance to unity, $op("Var")[tilde(phi)_text("OBF")(bold(q))]=1$, and thus the resulting OBF SSNR is given by the magnitude of its CTF:
$
  text("SSNR")_text("OBF")(bold(q)) = 1/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$

== Least Squares Matched Filter <sec-wdd>

The OBF estimator above improves SSB by normalizing the coherent sum, but it is not formally a least-squares estimator.
The proper matched-filter solution for recovering $tilde(phi)(bold(q))$ from the WPOA forward model is obtained by minimizing: $sum_bold(k) abs(G(bold(q),bold(k)) - Gamma(bold(q),bold(k))tilde(phi)(bold(q)))^2$.
This yields the following matched-filter estimator:
$
  tilde(phi)_text("MF")(bold(q)) =  (sum_bold(k)Gamma^*(bold(q),bold(k)) G(bold(q), bold(k)))/(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2 + epsilon(bold(q))).
$<eq-mf-recon>

While @eq-mf-recon is simple, direct evaluation in detector-space is numerically unstable:
the numerator contains highly oscillatory phases from $Gamma(bold(q),bold(k))$, and the denominator depends on the squared magnitude of a rapidly varying overlap kernel.
Applying Parseval's theorem and inverse Fourier transforming over $bold(k)$ gives:
$
  W(bold(q),bold(rho)) = cal(F)^(-1){Gamma(bold(q),bold(k))}, quad H(bold(q),bold(rho)) = cal(F)^(-1){G(bold(q),bold(k))},
$
where $bold(rho)$ is the detector separation.
The matched-filter estimator in the mixed-domain representation is:
$
  tilde(phi)_text("MF-mix")(bold(q)) = (integral W^*(bold(q),bold(rho)) H(bold(q),bold(rho)) d bold(rho))/(integral abs(W(bold(q),bold(rho)))^2 d bold(rho) + epsilon(bold(q))).
$

This utilizes the fact that the kernel $W(bold(q),bold(rho))$ is highly-localized in $rho$, suggesting that we can further improve numerical stability by switching to a pixelwise normalization, instead of a global inner product:
$
  tilde(phi)_text("WDD")(bold(q)) = integral (W^*(bold(q),bold(rho)) H(bold(q),bold(rho)))/(abs(W(bold(q),bold(rho)))^2  + epsilon(bold(q),bold(rho))) d bold(rho).
$<eq-wdd-recon>

When only one of the aperture-overlap sidebands is used to form the kernel $W(bold(q),bold(rho)) = cal(F)^(-1){tilde(psi)(bold(k-q))tilde(psi)^*(bold(k)))}$, @eq-wdd-recon is referred to as the _Wigner distribution deconvolution (WDD)_ method @Rodenburg_1992 @Li_2014 @Yang_2017. 

The matched-filter (and equivalently WDD) estimator can be characterized by a contrast transfer function by inserting the forward model into @eq-mf-recon:
$
  cal(L)_text("MF")(bold(q)) =  (sum_bold(k) abs(Gamma(bold(q),bold(k)))^2 )/(sum_bold(k)abs(Gamma(bold(q),bold(k)))^2 + epsilon(bold(q))).
$
Note that for sufficiently small regularization $epsilon(bold(q))$, the matched-filter CTF approaches unity, implying perfect phase transfer.
This is misleading, since the matched-filter noise variance is similarly increased:
$
  sqrt(op("Var")[tilde(phi)_text("MF")(bold(q))]) = sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2)/ (sum_bold(k) abs(Gamma(bold(q),bold(k)))^2) = 1/(sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2)),
$
to obtain an SSNR which is identical to the OBF SSNR:
$
  text("SSNR")_text("MF")(bold(q)) =  1/2 sqrt(sum_bold(k) abs(Gamma(bold(q),bold(k)))^2).
$

This highlights an important subtlety: the statistically-reliable information content is the same for all three linear estimators we have explored so far, namely SSB, OBF, and MF/WDD.

== Quadratic Approximation <sec-parallax>

The methods we have introduced so far all relied on the full aperture-overlap kernel $Gamma(bold(q),bold(k))$, which is expensive to compute numerically.
A natural question is whether a computationally efficient approximation exists that retains most of the SSB information content.

The _tilt-corrected bright-field (tcBF) STEM_ @Nguyen_2016 @Spoth_2017 @Yu_2025 or _parallax imaging_ @Varnavides_2023 @Varnavides_2024 @Varnavides_2025 method originated independently, based on the reciprocity principle that a virtual bright-field image formed form a given detector frequency in a defocused acquisition appears laterally shifted in real-space due to the parallax effect.
Computationally reversing these shifts, with subpixel accuracy using a detector-frequency-dependent phase ramp, restores all virtual BF images into a common focal plane, where they can be coherently summed.

Formally, this parallax correction is equivalent to applying a detector-frequency-dependent phase factor $exp[upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)]$ to the virtual bright-field images, where $nabla_bold(k) chi(bold(k))$ is the gradient of the aberration surface at bright field frequency $bold(k)$.
To see connection with SSB explicitly, we Taylor-expand $Gamma(bold(q),bold(k))$ to first order in $bold(q)$:
$
  Gamma(bold(q),bold(k)) approx underbrace(A(bold(k))[A(bold(q-k))upright(e)^(-upright(i)chi(bold(q))) - A(bold(q+k))upright(e)^(upright(i) chi(bold(q)))],
Beta(bold(q),bold(k))) upright(e)^(upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)),
$
where $Beta(bold(q),bold(k))$ contains the aperture-overlap terms, while the $exp[upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)]$ factor produces the parallax shift.
Thus, parallax imaging can be seen as a quadratic approximation to SSB, where only the first-order-aberrations-induced phase ramp is retained.
Combined with a global phase-flipping operation $op("sgn")[sin[chi(bold(q))]]$, parallax imaging provides a remarkably robust and computationally efficient approximation to SSB @Varnavides_2025:
$
  tilde(phi)_text("prlx")(bold(q)) = sum_(bold(k) in bold(k)_text("BF")) G(bold(q), bold(k)) upright(e)^(-upright(i) nabla_bold(k) chi(bold(k)) dot bold(q)) .
$<eq-par-recon>

The corresponding CTF is obtained by summing the approximate kernel $Beta(bold(q),bold(k))$ over the bright-field disk:
$
  cal(L)_text("prlx")(bold(q)) &= upright(i)/2 sum_bold(k) Beta(bold(q),bold(k)) \
  &= -upright(i) sin[chi(bold(q))] [A star A](bold(q)),
$
which reduces to the axial illumination CTF, modulated by the aperture autocorrelation function.

Since the parallax estimator simply applies a phase ramp to each virtual bright-field image before coherently summing, the noise contributions retain unit variance.
Consequently, the parallax SSNR is given by:
$
  text("SSNR")_text("prlx")(bold(q)) = abs(sin[chi(bold(q))]) [A star A](bold(q)),
$

== First Moment Projection <sec-icom>

An alternative and computationally efficient route to direct STEM phase retrieval is to take the first moment of the aperture–overlap function, known either as _integrated center-of-mass (iCOM) imaging_ or _integrated differential phase contrast (iDPC or DPC)_ @Dekkers_1974 @Lazic_2016.

Starting from the WPOA CTF expression in @eq-ctf and using a vectorial detector response $D(bold(k)) = bold(k)$, we obtain the vector COM transfer function as:
$
  cal(bold(L))_text("COM")(bold(q)) &= upright(i)/2 integral Gamma(bold(q),bold(k)) thin bold(k) thin d bold(k) \
  &= (upright(i) thin bold(q))/2 [tilde(psi) star tilde(psi)](bold(q)),
$
i.e. the first moment of the aperture-overlap function which is proportional to probe autocorrelation weighted by $bold(q)$.
Since Fourier differentiation satisfies $cal(F)_(bold(r) arrow bold(q)){nabla_bold(r) phi(bold(r))} = upright(i) bold(q) thin tilde(phi)(bold(q))$, we recognize the measured COM signal as a filtered estimate of the phase gradient, with the filter given by the probe autocorrelation.

To obtain the specimen phase, we Fourier-integrate the vector COM measurement to obtain:
$
  tilde(phi)_text("iCOM")(bold(q)) = sum_(bold(k) in bold(k)_text("BF")) (bold(q) dot [G(bold(q),bold(k)) thin bold(k)]) / (upright(i) abs(bold(q))^2).
$<eq-icom-recon>
Applying the same integration to the vectorial CTF yields the scalar iCOM transfer function:
$
  cal(L)_text("iCOM")(bold(q)) = upright(i) [tilde(psi) star tilde(psi)](bold(q)),
$
showing explicitly that iCOM reconstructs the specimen phase convolved with the probe autocorrelation @Bekkevold_2025.

Since COM is a first-moment measurement and each Fourier component of the estimated iCOM phase is obtained by integrating the COM signal and dividing by $abs(bold(q))$, the noise in the reconstruction scales with $abs(bold(q))$ @Varnavides_2025_ssnr:
$
  text("SSNR")_text("iCOM")(bold(q)) = (abs([tilde(psi) star tilde(psi)](bold(q))))/(abs(bold(q))),
$
highlighting that while the iCOM CTF implies low spatial frequencies should transfer with unit contrast, the corresponding SSNR shows these components become increasingly noisy in practice @Varnavides_2023 @Yu_2025 @Varnavides_2025_ssnr.

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  placement: auto,
  pseudocode-list(
    booktabs:true,
    booktabs-stroke:0.5pt + black,
    line-numbering:none,
    hooks: .5em,
    numbered-title: [
      Unified direct STEM phase retrieval (SSB, OBF, MF, prlx, iCOM)
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
    • construct upsampled and $theta$-rotated spatial frequency grid $bold(q)'$
    
    *Reconstruction:* \
    + *for* each BF index $i=1$ to $N_text("BF")$:  
      + $G(bold(q)) arrow.l cal(F)_(bold(r) arrow bold(q)){ I_text("BF")[i](bold(r))}$  
          #h(1fr) #text(rgb("#808080"))[(Fourier-transform vBF image)]  
      + $G(bold(q)') arrow.l op("tile")_f [G(bold(q))]$  
          #h(1fr) #text(rgb("#808080"))[(upsample by Fourier tiling)]
      + $H(bold(q)') arrow.l cases(
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/abs(Gamma(bold(q)',bold(k)_text("BF"))) quad &"if SSB",
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/sqrt(sum_(bold(k)in bold(k)_text("BF"))abs(Gamma(bold(q)',bold(k)_text("BF")))^2) quad &"if OBF",
        -upright(i) thin Gamma^*(bold(q)',bold(k)_text("BF"))\/(sum_(bold(k in bold(k)_text("BF")))abs(Gamma(bold(q)',bold(k)_text("BF")))^2 + epsilon(bold(q)')) quad &"if MF",
        #h(0.85em) exp[-upright(i) nabla_bold(k) chi(bold(k)_text("BF")) dot bold(q)'] thin op("sgn")[sin[chi(bold(q)')]] quad &"if prlx",
        -upright(i) thin bold(k)_text("BF") dot bold(q)' \/ abs(bold(q))^2 quad &"if iCOM"
      )$ #h(1fr) #text(rgb("#808080"))[(compute estimator kernel)]
      + $I'(bold(r)') +#h(-0.1em)= Re[cal(F)^(-1)_(bold(q)' arrow bold(r)'){G(bold(q)') H(bold(q)')}] \/ N_text("BF")$ #h(1fr) #text(rgb("#808080"))[(apply kernel and accumulate)]
    + *end*\
  ],
) <unified-pseudocode>

== Unified Comparison of Direct STEM Phase Estimators

The phase estimators introduced above -- SSB, OBF, MF/WDD, parallax, and iCOM -- all originate from the same WPOA forward model in @eq-wpoa-forward and additive noise model in @eq-noise-model.
They primarily differ in i) how they weight the bright-field intensities, ii) how they normalize the coherent sum, and iii) how much of the full aperture-overlap kernel they retain.

SSB performs an unnormalized coherent projection using the full aperture-overlap kernel.
OBF applies a noise-flattening scalar normalization.
MF/WDD implements the least-squares matched filter, either in detector-space (MF) or in a mixed-domain (WDD).
Parallax imaging uses a first-order approximation to the aperture-overlap kernel, keeping only the detector-frequency-dependent phase ramp $upright(e)^(upright(i) nabla_bold(k) chi(bold(k))dot bold(q))$.
It is computationally cheap, and its subpixel accuracy enables scan step-size upsampling @Varnavides_2025.
Finally, iCOM bypasses the overlap-kernel entirely, and instead takes the first moment of the bright-field intensities and reconstructs the phase by Fourier-integration of the resulting COM signal.

With the exception of iCOM, these techniques rely on an accurate estimation of the aberrations, which can be calculated through optimization routines, based on self consistency error @Varnavides_2025, or in the case of parallax through fitting of cross-correlation shifts of real space images with a linear systems of equations @Varnavides_2023 @Yu_2025.
@unified-pseudocode shows a unified pseudocode for the direct estimators we have seen so far, using a loop over bright-field pixels $bold(k)_text("BF")$.
This leverages the fact that the aperture-overlap function is identically zero outside the probe aperture, is computationally more efficient, and enables natural upsampling via Fourier-tiling @Varnavides_2025.
Due to the mixed-domain requirement, WDD cannot be computed by looping solely over bright-field pixels.

== Impact of Direct Techniques on Materials Science

As highlighted in @fig-ctf, the ideal approach depends on the nature of the data and acquisition parameters. 
For in focus experiments, iCOM is often the preferred approach with the low computational overhead of this technique making it most compatible with in-situ approaches @bekkevold2024ultra.
Conversely, parallax reconstructions are often performed for defocused acquisitions using large step-sizes, e.g. for beam-sensitive biological samples @Berk_2024 @Yu_2025.
The SSB, OBF, and MF/WDD techniques, performing a full deconvolution of the aperture-overlap are suited for both in-focus and defocused acquisitions @Varnavides_2025, and can in-fact correct residual higher-order aberrations @Susi_2025.
However, acquisitions on aberration corrected instruments are often dominated by first-order aberrations such as defocus and astigmatism, suggesting the quadratic approximation provided by parallax yields a nearly identical reconstruction as SSB, OBF, or MF/WDD.

Ultimately these approaches provide a powerful approach for phase retrieval for materials science samples, with examples including carbon nanotubes @yang2016simultaneous, 2D materials @o2022increasing @Susi_2025, and metal organic frameworks @Ma_2025, @shen2020imaging, and battery samples @lozano2018low. 
These techniques are computationally efficient, meaning with modern computational resources,they can be reconstructed "live" during acquisition @Yu_2022 @Ooe_2021 @Pelz_2022 @Strauch_2021.
For low dose experiments, the direct phase retrieval techniques perform remarkably well as compared to their more computationally expensive counterparts @Varnavides_2025_ssnr, suggesting that more advanced reconstruction approaches may not be needed offline.
However, for thick samples and experiments with higher electron fluence, iterative approaches outperform their direct phase retrieval counterparts as described in @sec-iterative.

= Iterative Ptychography <sec-iterative>

The direct phase-retrieval methods presented above provide fast, interpretable, and often remarkably robust reconstructions when multiple scattering is negligible.
However, applying STEM phase retrieval to complex materials science questions requires going beyond the WPOA.
Real specimens impart strong phase shifts, redistribute intensity nonlinearly, and may channel electrons through multiple atomic layers @Williams_2009 @Carter_2016 @Kirkland_2020.
These effects are fundamentally incompatible with the linear WPOA model, requiring _iterative methods_ based on the strong-phase object approximation, in which the specimen is modeled according to @eq-ms.

Iterative approaches offer several key advantages.
First, they enable super-resolution @Maiden_2009, allowing recovery of specimen information beyond the twice numerical-aperture limit of direct methods, and without imposing scan-step size restrictions.
Second, they are remarkably flexible: the same mathematical framework can be extended to incorporate depth-information (multislice @Chen_2021), multiple scattering channels (e.g. electrostatic and magnetic potentials @Varnavides_2023_mag), or partial-coherence in the converged illumination (mixed-state @Thibault_2013).
Third, iterative reconstructions do not require perfect prior knowledge of the converged illumination; they naturally support blind deconvolution, jointly solving for both the specimen phase and probe aberrations.
Finally, the optimization framework underlying iterative approaches naturally interfaces with modern machine-learning tools, enabling reconstructions driven by autodifferentiation or deep generative priors @McCray_2025.

In the following sections, we develop the major families of iterative methods, beginning with classical projection-based algorithms, then moving to gradient-based approaches, and finally extending to multislice, mixed-state, and machine-learning–based formulations.

== Single Slice Iterative Methods <sec-single-slice>

Iterative reconstruction methods begin from the strong-phase object approximation, in which the specimen is represented by a single transmission function related to the projected potential:
$
  cal(O)(bold(r)) = exp[upright(i) thin phi(bold(r))].
$
Unlike the WPOA, the detected bright-field intensity no longer responds linearly to $phi(bold(r))$; instead, the exit wave and corresponding diffraction pattern for each scan position $bold(R)_j$ are given by:
$
  psi_text("exit")^((j)) (bold(r)) &= cal(O)(bold(r)) psi(bold(r)-bold(R)_j) \ 
  I_text("model")^((j)) (bold(k)) &= abs(cal(F)_(bold(r) arrow bold(k)){tilde(psi)_text("exit")^((j))(bold(r))})^2 = abs(tilde(psi)_text("exit")^((j))(bold(k)))^2.
$
Single-slice ptychography attempts to recover estimates for the complex-valued object $cal(O)(bold(r))$, and often refine the illumination estimate $psi(bold(r))$, by enforcing consistency between the measured intensities $I_text("meas")^((j)) (bold(k))$ and the modeled intensities using the current object and illumination estimates.
The nonlinear modulus constraint $abs(tilde(psi)_text("exit")^((j))(bold(k))) = sqrt(I_text("meas")^((j))(bold(k)))$, must be satisfied for each scan position independently, requiring iterative algorithms that repeatedly enforce constraints in real and Fourier space.
These algorithms can be grouped in two broad families: proximal gradient / projection-set methods and gradient-based optimization methods @Varnavides_2023.

=== Projection-set methods
ER, DM, RAAR

=== Gradient-based methods
ePie, SGD

== Beyond single slice ptychography 
=== Mixed-state

=== Multi-slice ptychography

=== Regularization
Explain how methods share a data-consistency constraint/loss, differ in object/probe updated and regularization
== Machine learning methods 
autodifferentiation 
generative priors 




= Outlook
Despite recent studies that demonstrate the ability to perform ptychographic reconstructions on uncorrected instruments @nguyen2024achieving, including with small converge angles @blackburn2025sub, proper reconstruction on most samples benefits from an aberration corrector and overlap in reciprocal space assures beams are phase relative to each other leading to a unique and accurate sample reconstruction. 
Ultimately phase retrieval approaches in materials science still largely depend on expensive hardware, including advanced detectors and aberration correctors.


= Acknowledgement 
Work at the Molecular Foundry was supported by the Office of Science, Office of Basic Energy Sciences, of the U.S. Department of Energy under Contract No. DE-AC02-05CH11231.


#pagebreak()
#bibliography(
  "references.bib",
  style: "american-chemical-society"
)